# Test Data

Notes on preparing data for testing in Glacier.

## Preparing bags

Build bags for a list of resources and compress them with tar gzip.

1. Copy `identifiers.json` to `/opt/figgy/current` on a Figgy server.
2. Start the Figgy rails console
3. Paste the following method:
  
  ```
  def make_bags(identifiers, archived_bag_path)
    exporter = Bagit::BagExporter.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:bags),
      storage_adapter: Valkyrie::StorageAdapter.find(:bags),
      query_service: Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    )
    query_service = Valkyrie.config.metadata_adapter.query_service

    # Make directory for gzipped bags
    FileUtils.mkdir_p archived_bag_path

    identifiers.each do |id|
      puts id
      resource = query_service.find_by(id: Valkyrie::ID.new(id))
      exporter.export(resource: resource)
      bag_path = exporter.metadata_adapter.bag_path(id: resource.id)
      out_path = File.join(archived_bag_path, "#{id}.tar.gz")
      system "tar -zcvf #{out_path} #{bag_path}"
    end
  end
  ```
4. Then paste:

  ```
  identifiers = JSON.parse(File.read("tmp/identifiers.json"))["identifiers"]
  archived_bag_path = "tmp/archived_bags"
  make_bags(identifiers, archived_bag_path) 
  ```

## Upload bags to Glacier

On a server with access to the bags directory

1. Clone the paws git repo and bundle install
2. Start the Figgy rails console
  
  ```
  AWS_ACCESS_KEY_ID= AWS_SECRET_ACCESS_KEY= bundle exec irb
  ```
2. Paste this code:
  
  ```
  require 'paws'

  def upload_bags(archived_bag_path, glacier)
    Dir["#{archived_bag_path}/*.gz"].each do |path|
      puts path
      id = File.basename(path, ".tar.gz")
      file = File.open(path)
      glacier.upload(file: file, part_size: 16777216, archive_description: id)
    end
  end

  glacier = Paws::Glacier.new(account: 'account-number', vault: 'vault-name')
  archived_bag_path = "tmp/archived_bags"
  upload_bags(archived_bag_path, glacier)
  ```
