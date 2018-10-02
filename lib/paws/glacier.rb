# frozen_string_literal: true

module Paws
  class Glacier
    attr_reader :vault
    ONE_MB = 1024 * 1024

    # @param account [String]
    # @param vault [String]
    # @param region [String]
    def initialize(account:, vault:, region: 'us-east-1')
      @vault = Aws::Glacier::Vault.new(account, vault, region: region)
    end

    # @param file [IO]
    # @param part_size [Integer] must be a megabyte (1024 KB) multiplied by a power of 2
    # @param archive_description [String]
    # @return [Aws::Glacier::Types::ArchiveCreationOutput]
    def upload(file:, part_size: ONE_MB, archive_description: nil)
      multipart = initiate_multipart_upload(part_size: part_size,
                                            archive_description: archive_description)
      # Read the file in parts and upload each part separately.
      start_position = 0
      until file.eof?
        part = file.read(part_size)
        multipart.upload_part(
          checksum: checksum(part),
          range: range(start_position, part_size, file.size),
          body: part
        )
        start_position += part_size
      end

      # Generate checksum for whole file and send command to complete upload.
      multipart.complete(archive_size: file.size, checksum: file_checksum(file))
    end

    # @param job [Aws::Glacier::Job]
    # @param part_size [Integer]
    # @param base_path [String]
    # @return [String] path to downloaded file
    def download_retrieved_archive(job:, part_size: ONE_MB, base_path: "./tmp")
      return nil unless job.archive_id
      file_path = "#{base_path}/#{job.archive_id}.tar.gz"
      download_output(job: job, part_size: part_size, file_size: job.archive_size_in_bytes, file_path: file_path)

      file_path
    end

    # @param job [Aws::Glacier::Job]
    # @param part_size [Integer]
    # @param base_path [String]
    # @return [String] path to downloaded file
    def download_retrieved_inventory(job:, part_size: ONE_MB, inventory_path: "./tmp/inventory.json")
      File.open(inventory_path, 'wb') do |file|
        download_output(job: job, part_size: part_size, file_size: job.inventory_size_in_bytes) do |output|
          chunk = output.body.read
          file.write(chunk)
        end
      end

      inventory_path
    end

    # Calculate Glacier tree hash for entire file.
    # @param file [IO]
    # @return [String]
    def file_checksum(file)
      tree_hash = Aws::Glacier::TreeHash.new
      file.rewind
      until file.eof?
        chunk = file.read(ONE_MB)
        tree_hash.update(chunk)
      end

      tree_hash.digest
    end

    private

      # Calculate Glacier tree hash for chunk of data.
      # @param chunk [String]
      # @return [String]
      def checksum(chunk)
        tree_hash = Aws::Glacier::TreeHash.new
        # Calculate total number of 1MB chunks.
        total_chunk_parts = (chunk.size / ONE_MB.to_f).ceil

        if total_chunk_parts == 1
          # Add a single chunk to the tree hash.
          tree_hash.update(chunk)
        else
          # Extract 1MB parts from the chunk and add to tree hash.
          (1..total_chunk_parts).each do |chunk_part_number|
            start_byte = (chunk_part_number - 1) * ONE_MB
            end_byte = start_byte + ONE_MB
            chunk_part = chunk[start_byte...end_byte]
            tree_hash.update(chunk_part)
          end
        end

        tree_hash.digest
      end

      # @param job [Aws::Glacier::Job]
      # @param part_size [Integer]
      # @param file_size [Integer]
      # @yield [Aws::Glacier::Types::GetJobOutputOutput]
      def download_output(job:, part_size:, file_size:, file_path:)
        total_parts = (file_size / part_size.to_f).ceil
        start_position = 0
        total_parts.times do
          range = range(start_position, part_size, file_size)
          output = job.get_output(range: range)
          chunk = output.body.read
          File.open(file_path, 'wb') do |file|
            file.write(chunk)
          end

          start_position += part_size
        end
      end

      # @param part_size [Integer]
      # @param archive_description [String]
      # @return [Aws::Glacier::MultipartUpload]
      def initiate_multipart_upload(part_size:, archive_description: nil)
        vault.initiate_multipart_upload(
          archive_description: archive_description,
          part_size: part_size
        )
      end

      # @param start_position [Integer]
      # @param part_size [Integer]
      # @param file_size [Integer]
      # @return [String]
      def range(start_byte, part_size, file_size)
        end_byte = start_byte + part_size - 1
        # Set end byte value to last byte in the file if this is the last range value.
        end_byte = end_byte > file_size ? file_size - 1 : end_byte
        "bytes #{start_byte}-#{end_byte}/*"
      end
  end
end
