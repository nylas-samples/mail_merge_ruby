# Mail Merge Template

This project will show you how to create a Mail Merge Template using Ruby and Sinatra.

## Setup

### System dependencies

- Ruby 3.1.1 or greater

### Gather environment variables

You'll need the following values:

```text
V3_TOKEN = ""
GRANT_ID = ""
```

Add the above values to a new `.env` file:

```bash
$ touch .env # Then add your env variables
```

### Install dependencies

```bash
$ gem install dotenv
$ gem install sinatra
$ gem install sinatra-flash
$ gem install nylas
$ gem install puma

```

## Usage

Clone the repository. Go to your terminal and type:

```bash
$ ruby mail_merge.rb
```

Create an .csv file with information like this:

```
Name | Last_Name | Account | Address | Email | Gift | Attachment
```

The only "mandatory" fields are: *Name* and *Email*. You can delete, update or create new fields. 


And go to `http://localhost:4567`

You will presented with a form, enter the Subject, Body and select the .csv file that you're going to use and simply press submit to start sending personlized emails.

## Read the blog post

- [How to Create a Mail Merge Template with Ruby](https://www.nylas.com/blog/how-to-create-a-mail-merge-template-with-ruby-and-gmail/)
