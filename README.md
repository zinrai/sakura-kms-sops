# sakura-kms-sops

A tool to use [SOPS](https://github.com/getsops/sops) with [SAKURA Cloud KMS](https://cloud.sakura.ad.jp/products/kms/).

## Overview

[SOPS (Secrets OPerationS)](https://github.com/getsops/sops) is a powerful tool for managing secrets in configuration files. While SOPS natively supports major cloud KMS providers like AWS KMS and GCP KMS, it does not support SAKURA Cloud KMS.

However, SOPS does support [age](https://github.com/FiloSottile/age) encryption through the `SOPS_AGE_KEY_CMD` environment variable, which allows executing an external command to retrieve the age secret key.

This led to the idea: **if we encrypt the age secret key with SAKURA Cloud KMS and decrypt it on-demand using th `SOPS_AGE_KEY_CMD` mechanism, we can effectively use SOPS with SAKURA Cloud KMS as the root of trust.**

`sakura-kms-sops` implements this bridge approach:

1. The age secret key is encrypted and stored using SAKURA Cloud KMS
2. When SOPS needs to decrypt files, it calls the command specified in `SOPS_AGE_KEY_CMD`
3. This command uses [sakura-kms](https://github.com/zinrai/sakura-kms) to decrypt the age secret key
4. SOPS receives the decrypted age key and uses it to decrypt the actual secrets

This way, SAKURA Cloud KMS becomes the central key management system, while SOPS continues to work with its familiar workflow.

## Prerequisites

- [sops](https://github.com/getsops/sops)
- [sakura-kms](https://github.com/zinrai/sakura-kms)

## Configuration

Set the age key file path:

```bash
$ export SAKURACLOUD_KMS_KEY_FILE="age-key.kms.enc"
```

## Usage

```bash
$ sakura-kms-sops.sh [sops arguments...]
```

### Examples

Edit encrypted file:

```bash
$ sakura-kms-sops.sh edit secrets.yaml
```

Decrypt file:

```bash
$ sakura-kms-sops.sh -d secrets.yaml
```

Encrypt file:

```bash
$ sakura-kms-sops.sh -e plain.yaml > encrypted.yaml
```

## Setup

### 1. Generate age key pair

```bash
$ age-keygen -o age-key.txt
```

### 2. Encrypt the age secret key with SAKURA Cloud KMS

```bash
$ cat age-key.txt | sakura-kms encrypt -output age-key.kms.enc
```

### 3. Configure sops to use the age public key

Extract the public key from `age-key.txt` and add it to your `.sops.yaml`:

```yaml
creation_rules:
  - age: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 4. Use sakura-kms-sops

```bash
$ sakura-kms-sops.sh edit secrets.yaml
```

## How It Works

1. `sakura-kms-sops` sets the `SOPS_AGE_KEY_CMD` environment variable
2. The command specified in `SOPS_AGE_KEY_CMD` decrypts the age key using sakura-kms
3. `sops` executes the command and receives the decrypted age key via stdout
4. `sops` uses the age key to encrypt/decrypt files

## License

This project is licensed under the [MIT License](./LICENSE).
