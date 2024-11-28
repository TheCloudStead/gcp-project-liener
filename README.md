# gcp-project-liener

As seen on Medium:

https://medium.com/@root_44345/serverless-gcp-project-liener-opentofu-python-and-a-cloud-function-028efc55e56e

```
git clone https://github.com/TheCloudStead/gcp-project-liener
cd gcp-project-liener/src/
zip function.zip main.py requirements.txt
cd ../tofu
# update variables.tf
tofu fmt
tofu init
tofu apply
```
