name: Deploy Azure Resume

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  AZURE_FUNCTIONAPP_PACKAGE_PATH: './backend'
  PYTHON_VERSION: '3.9'

jobs:
  terraform:
    name: 'Terraform Infrastructure'
    runs-on: ubuntu-latest
    outputs:
      function_app_name: ${{ steps.terraform_output.outputs.function_app_name }}
      storage_account_name: ${{ steps.terraform_output.outputs.storage_account_name }}
      website_url: ${{ steps.terraform_output.outputs.website_url }}
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.5.0
        terraform_wrapper: false

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Terraform Init
      run: |
        cd terraform
        terraform init

    - name: Terraform Plan
      run: |
        cd terraform
        terraform plan

    - name: Terraform Apply
      if: github.ref == 'refs/heads/main'
      run: |
        cd terraform
        terraform apply -auto-approve

    - name: Get Terraform Outputs
      if: github.ref == 'refs/heads/main'
      id: terraform_output
      run: |
        cd terraform
        echo "function_app_name=$(terraform output -raw function_app_name)" >> $GITHUB_OUTPUT
        echo "storage_account_name=$(terraform output -raw storage_account_name)" >> $GITHUB_OUTPUT
        echo "website_url=$(terraform output -raw website_url)" >> $GITHUB_OUTPUT

  build-and-deploy-backend:
    name: 'Build and Deploy Backend'
    runs-on: ubuntu-latest
    needs: terraform
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Python ${{ env.PYTHON_VERSION }} Environment
      uses: actions/setup-python@v4
      with:
        python-version: ${{ env.PYTHON_VERSION }}

    - name: Install dependencies
      run: |
        cd backend
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Run tests
      run: |
        cd backend
        python -m pytest tests/ -v

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Deploy to Azure Function App
      uses: Azure/functions-action@v1
      with:
        app-name: ${{ needs.terraform.outputs.function_app_name }}
        package: ${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}
        publish-profile: ${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
        scm-do-build-during-deployment: true
        enable-oryx-build: true

  deploy-frontend:
    name: 'Deploy Frontend'
    runs-on: ubuntu-latest
    needs: [terraform, build-and-deploy-backend]
    if: github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18'

    - name: Install dependencies
      run: |
        cd frontend
        npm install

    - name: Build frontend
      run: |
        cd frontend
        npm run build

    - name: Azure Login
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}

    - name: Deploy to Azure Storage
      uses: azure/CLI@v1
      with:
        inlineScript: |
          az storage blob upload-batch \
            --account-name ${{ needs.terraform.outputs.storage_account_name }} \
            --auth-mode key \
            --destination '$web' \
            --source './frontend/dist' \
            --overwrite

    - name: Purge CDN (if configured)
      run: |
        echo "Add CDN purge command here if using Azure CDN"

  notify:
    name: 'Notify Deployment Status'
    runs-on: ubuntu-latest
    needs: [terraform, build-and-deploy-backend, deploy-frontend]
    if: always() && github.ref == 'refs/heads/main'
    
    steps:
    - name: Notify Success
      if: ${{ needs.terraform.result == 'success' && needs.build-and-deploy-backend.result == 'success' && needs.deploy-frontend.result == 'success' }}
      run: |
        echo "🎉 Deployment successful!"
        echo "Website URL: ${{ needs.terraform.outputs.website_url }}"
        echo "Resume is live and ready!"

    - name: Notify Failure
      if: ${{ needs.terraform.result == 'failure' || needs.build-and-deploy-backend.result == 'failure' || needs.deploy-frontend.result == 'failure' }}
      run: |
        echo "❌ Deployment failed. Please check the logs."
        exit 1