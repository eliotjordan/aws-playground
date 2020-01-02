# Glacier

## Vaults

[Vault API](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Glacier/Vault.html)

### Create a new vault

```
vault = Aws::Glacier::Vault.new('account-id', 'vault-name', {region: 'us-east-1'})
vault.create()
```

### Inventory retrieval
Vault inventory is run once every ~24 hours. Use this command to retreive the latest version.

```
job = vault.initiate_inventory_retrieval()
```

## Archives

[Archive API](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Glacier/Archive.html)

### Upload an archive

```
archive = vault.upload_archive({
  archive_description: "Bob archive",
  checksum: Digest::SHA256.file('spec/fixtures/bob.jpg').to_s,
  body: IO.read('spec/fixtures/bob.jpg')
})
```
### Get an archive object by id

```
archive = vault.archive('archive-id')
```

### Retrieve an archive

```
archive = Aws::Glacier::Archive.new('account-id', 'vault-name', 'archive-id', {region: 'us-east-1'})
job = archive.initiate_archive_retrieval()
```

Retrieval takes 3 -5 hours (unless expedited or bulk). Poll `vault.jobs_in_progress` to wait for the retrieval
to complete.

```
job.completed
```

## Jobs

[Job API](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Glacier/Job.html)

### Get jobs in progress

```
jobs_in_progress = vault.jobs_in_progress({
  completed: "false"
})
jobs_in_progress.count
job = jobs_in_progress.first
```

### Get succeeded jobs

```
succeeded_jobs = vault.succeeded_jobs({
  completed: "true"
})
```

Make sure to filter by archive_id to get the correct file from the vault.

### Get job output

Download the entire output.

```
output = job.get_output()
```

Download a range to break the output into multiple chunks.

```
output = job.get_output({
  range: "bytes=0-1048575",
})
```

### Save downloaded file

```
File.open('/output/path/bob.jpg', 'w') do |f| 
  f.puts(output.body.read)
end
```

## Multipart Upload

[MultipartUpload API](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/Glacier/MultipartUpload.html)

### Initiate a multipart upload

Part size is the size of each part except the last, in bytes. The last part can be smaller than this part size. The value of part_size must be a megabyte (1024 KB) multiplied by a power of 2, for example 1048576 (1 MB), 2097152 (2 MB), 4194304 (4 MB), 8388608 (8 MB), and so on. The minimum allowable part size is 1 MB, and the maximum is 4 GB (4096 MB).

NOTE: There is a maximum of 10000 parts allowed, so the part size must be set high enough to accommodate this limit. 

```
multipartupload = vault.initiate_multipart_upload({
  archive_description: "A big file to archive",
  part_size: 1048576
})
```

### Upload a part

```
multipart_upload.upload_part({
  checksum: "SHA256-tree-hash-of-part...",
  range: "1048576-2097152",
  body: "data"
})
```

### Complete a multipart upload

```
multipart_upload.complete({
  archive_size: 2097152,
  checksum: "SHA256-tree-hash-of-entire-archive...",
})
```

## Paws::Glacier

```
glacier = Paws::Glacier.new(account: 'account-id', vault: 'vault-name')
file = File.open('spec/fixtures/bob.jpg')
glacier.upload(file: file, part_size: 1048576, archive_description: "Bob uploaded")
```

## Rake Tasks

### Setup
```
  AWS_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXX
  AWS_ACCESS_SECRET=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
  AWS_ACCOUNT_ID=122345667890
  PART_SIZE=1073741824 # optional, defaults to 1MB
```

### Upload
```
$ rake upload VAULT_NAME=myvault UPLOAD_FILENAME=myfile.tar.gz
```

Uploads the file and outputs the archive ID:
```
myfile.tar.gz => XXXXXXXXXXXXXXXXXXXX-XXXXX-XXXXXXXXXXXXXXX-XXXXXXXX
```

### Download
```
$ rake download VAULT_NAME=myvault ARCHIVE_ID=XXXXXXXXXXXXXXXXXXXX-XXXXX-XXXXXXXXXXXXXXX-XXXXXXXX
```

Saves the file to `XXXXXXXXXXXXXXXXXXXX-XXXXX-XXXXXXXXXXXXXXX-XXXXXXXX.tar.gz`
