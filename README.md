# gcp-project-liener

### Introduction

This repository contains the code for deploying a serverless GCP Cloud Function that adds accidental deletion liens on projects using OpenTofu and Python. You can find a detailed explanation of this setup in the Medium article:

[**Serverless GCP Project Liener with OpenTofu, Python, and a Cloud Function**](https://thecloudstead.medium.com/serverless-gcp-project-liener-opentofu-python-and-a-cloud-function-028efc55e56e)

### Prerequisites

- Google Cloud Platform account with permissions to deploy Cloud Functions.
- OpenTofu installed and configured.
- Python installed on your local machine.
- `gcloud` CLI configured to interact with your GCP account.

### Getting Started

Clone the repository and move into the appropriate directory:

```bash
git clone https://github.com/TheCloudStead/gcp-project-liener
cd gcp-project-liener/src/
```

### Packaging the Cloud Function

The Cloud Function code is contained in `main.py`, and the dependencies are in `requirements.txt`. To package the function for deployment:

```bash
zip function.zip main.py requirements.txt
```

### Deploying Infrastructure

Move to the OpenTofu configuration directory:

```bash
cd ../tofu
```

Before deploying, make sure to update the necessary variables in `variables.tf` to match your project configuration.

1. **Format the Configuration Files**:
   ```bash
   tofu fmt
   ```

2. **Initialize the Project**:
   ```bash
   tofu init
   ```

3. **Apply the Configuration**:
   ```bash
   tofu apply
   ```

   This command will deploy the necessary infrastructure, including the Cloud Function, which adds deletion liens to your GCP projects.

### Files Overview

- **main.py**: The core Python script for adding liens to GCP projects.
- **requirements.txt**: Lists Python dependencies needed for the Cloud Function.
- **variables.tf**: Contains configuration variables for OpenTofu, such as project IDs and resource settings.
- **tofu/**: Directory containing the OpenTofu scripts for deploying the infrastructure.

### Updating Cloud Function Logic

If you need to modify the logic of adding project liens, make edits in `main.py`. You can customize the conditions under which liens are added to suit your requirements.

### Tips

- Ensure you have correct permissions set for deploying Cloud Functions and managing project liens.
- Test your Cloud Function locally before deploying it to GCP to prevent runtime issues.
- Keep your `variables.tf` file updated to match your GCP project's settings.

### License

This project is licensed under the MIT License. See the `LICENSE` file for more details.

### Acknowledgments

Thank you to the readers of my Medium articles!