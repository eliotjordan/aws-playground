require "paws"

desc "Setup auth"
task :environment do
  @account_id = ENV["AWS_ACCOUNT_ID"]
  ONE_MB = 1024 * 1024
  @part_size = [ENV["PART_SIZE"].to_i, ONE_MB].max
  access_key = ENV["AWS_ACCESS_KEY"]
  access_secret = ENV["AWS_ACCESS_SECRET"]
  Aws.config.update({credentials: Aws::Credentials.new(access_key, access_secret)})
end

desc "Upload a file to Glacier"
task upload: :environment do
  vault_name = ENV["VAULT_NAME"]

  # make sure vault exists
  vault = Aws::Glacier::Vault.new(@account_id, vault_name, {region: "us-east-1"})
  vault.create() unless vault.data_loaded?

  # upload file
  filename = ENV["UPLOAD_FILENAME"]
  glacier = Paws::Glacier.new(account: @account_id, vault: vault_name)
  upload = glacier.upload(file: File.open(filename), part_size: @part_size, archive_description: filename)
  puts "#{filename} => #{upload.archive_id}"
end

desc "Download a file from Glacier"
task download: :environment do
  archive_id = ENV["ARCHIVE_ID"]
  vault_name = ENV["VAULT_NAME"]
  
  # start retrieval
  vault = Aws::Glacier::Vault.new(@account_id, vault_name, {region: 'us-east-1'})
  archive = vault.archive(archive_id)
  archive.initiate_archive_retrieval # this never shows up as completed

  # wait for retrieval to complete
  job = nil
  until job do
    job = vault.succeeded_jobs({completed: "true"}).select {|j| j.archive_id == archive_id }.first
    break if job
    puts "waiting... #{DateTime.now}"
    sleep 60
  end

  puts "downloading to #{archive_id}.tar.gz"
  glacier = Paws::Glacier.new(account: @account_id, vault: vault_name)
  glacier.download_retrieved_archive(job: job, part_size: @part_size, base_path: ".")
  puts "done"
end
