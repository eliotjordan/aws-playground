# aws-playground
Scripts and documentation for working with AWS services

## Initial Setup
```
$ bundle install
```

## AWS Interactive Console
```
$ aws-v3.rb
```

## Setting AWS Credentials

### Shared Credentials
AWS credentials profile file.

```
~/.aws/credentials
```

```
[default]
aws_access_key_id = your_access_key_id
aws_secret_access_key = your_secret_access_key
```

### Evironment Variables
```
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
```

### Aws.config
```
Aws.config.update({
   credentials: Aws::Credentials.new('your_access_key_id', 'your_secret_access_key')
})
```

### Client Object
```
s3 = Aws::S3::Client.new(
  access_key_id: 'your_access_key_id',
  secret_access_key: 'your_secret_access_key'
)
```

## Setting a Region

### Environment Variable
```
export AWS_REGION=us-east-1
```

###  Aws.config
```
Aws.config.update({region: 'us-east-1'})
```

### Client or Resource Object
```
s3 = Aws::S3::Resource.new(region: 'us-east-1')
```

