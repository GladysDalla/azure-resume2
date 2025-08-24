# Azure Resume Challenge - Cloud Engineer Portfolio

A serverless resume website built with Azure cloud services, demonstrating modern DevOps practices, Infrastructure as Code, and cloud-native architecture.

## 🏗️ Architecture

```
Internet → Azure Storage (Static Website) → Azure Function App → Cosmos DB
                                        ↓
                              Application Insights (Monitoring)
                                        ↓
                              Key Vault (Secrets Management)
```

## 🚀 Features

- **Serverless Architecture**: Azure Functions for API, Static Website hosting
- **Infrastructure as Code**: Complete infrastructure defined in Terraform
- **CI/CD Pipeline**: Automated deployment with GitHub Actions
- **Security First**: Managed Identity, Key Vault for secrets
- **Monitoring**: Application Insights integration
- **Visitor Counter**: Real-time visitor tracking with Cosmos DB
- **Responsive Design**: Mobile-friendly resume interface

## 🛠️ Technologies

### Backend
- **Azure Functions** (Python 3.9) - Serverless API
- **Cosmos DB** - NoSQL database for visitor counter
- **Application Insights** - Monitoring and telemetry
- **Key Vault** - Secrets management
- **Managed Identity** - Secure authentication

### Frontend
- **Azure Storage Static Websites** - Hosting
- **HTML5/CSS3/JavaScript** - Responsive design
- **Font Awesome** - Icons
- **Google Fonts** - Typography

### DevOps
- **Terraform** - Infrastructure as Code
- **GitHub Actions** - CI/CD pipeline
- **Azure CLI** - Deployment automation

## 📁 Project Structure

```
azure-resume/
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # Main Terraform configuration
│   ├── variables.tf    # Variable definitions
│   └── outputs.tf      # Output values
├── backend/             # Azure Function App
│   ├── function_app.py # Main function code
│   ├── requirements.txt# Python dependencies
│   ├── host.json       # Function app configuration
│   └── tests/          # Unit tests
├── frontend/            # Static website
│   ├── src/
│   │   ├── index.html  # Resume HTML
│   │   ├── style.css   # Styling
│   │   └── script.js   # JavaScript functionality
│   └── package.json    # Build configuration
├── .github/workflows/   # CI/CD Pipeline
│   └── deploy.yml      # GitHub Actions workflow
└── README.md           # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Azure Account** with active subscription
2. **Azure CLI** installed and configured
3. **Terraform** (v1.5+) installed
4. **GitHub Account** for CI/CD
5. **Node.js** (v18+) for frontend build

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/azure-resume
cd azure-resume
```

### 2. Azure Setup

Create a Resource Group:
```bash
az group create --name AzureResumeRG --location eastus
```

Create Service Principal for GitHub Actions:
```bash
az ad sp create-for-rbac \
  --name "github-azure-resume-sp" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/AzureResumeRG \
  --sdk-auth
```

### 3. GitHub Secrets

Add the following secrets to your GitHub repository:

- **AZURE_CREDENTIALS**: Full JSON output from Service Principal creation
- **AZURE_FUNCTIONAPP_PUBLISH_PROFILE**: Download from Azure Portal after initial deployment

### 4. Customize Content

Update the resume content in `frontend/src/index.html`:
- Personal information
- Experience details
- Skills and certifications
- Contact information

### 5. Deploy Infrastructure

Push to main branch to trigger automated deployment:
```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## 🔧 Local Development

### Backend (Azure Functions)

1. Install Azure Functions Core Tools
2. Install Python dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```
3. Run locally:
   ```bash
   func start
   ```

### Frontend

1. Install dependencies:
   ```bash
   cd frontend
   npm install
   ```
2. Start development server:
   ```bash
   npm run dev
   ```

## 📊 Monitoring

### Application Insights
- Function execution metrics
- Error tracking and diagnostics
- Performance monitoring
- Custom telemetry

### Key Metrics to Monitor
- Function execution count
- Response times
- Error rates
- Visitor count accuracy

## 🔒 Security Features

### Managed Identity
- Functions authenticate to Azure services without storing credentials
- Automatic credential rotation
- Principle of least privilege

### Key Vault Integration
- Secure storage of connection strings
- Runtime secret retrieval
- Access policies and auditing

### CORS Configuration
- Controlled cross-origin requests
- Production domain allowlisting

## 🏗️ Infrastructure Details

### Terraform Resources Created

| Resource | Purpose | Configuration |
|----------|---------|---------------|
| Resource Group | Container for all resources | `AzureResumeRG` |
| Storage Account | Static website hosting | Standard LRS, Static website enabled |
| Function App | Serverless API | Python 3.9, Consumption plan |
| Cosmos DB | Visitor counter database | SQL API, 400 RU/s |
| Application Insights | Monitoring and telemetry | Linked to Function App |
| Key Vault | Secrets management | Soft delete enabled |
| Log Analytics | Centralized logging | 30-day retention |

### Cost Estimation (Monthly)

| Service | Tier | Estimated Cost |
|---------|------|----------------|
| Storage Account | Standard LRS | $1-3 |
| Function App | Consumption | $0-5 |
| Cosmos DB | 400 RU/s | $24 |
| Application Insights | Basic | $0-2 |
| Key Vault | Standard | $1-3 |
| **Total** | | **$26-37/month** |

*Costs may vary based on usage patterns*

## 🚀 CI/CD Pipeline

### Workflow Stages

1. **Infrastructure Deployment**
   - Terraform plan and apply
   - Resource provisioning
   - Output variable capture

2. **Backend Deployment**
   - Python dependency installation
   - Unit test execution
   - Function App deployment

3. **Frontend Deployment**
   - Asset building and optimization
   - Upload to Storage Account
   - Cache invalidation

4. **Notification**
   - Deployment status
   - Website URL sharing

## 📈 Performance Optimization

### Frontend
- Minified CSS and JavaScript
- Optimized images
- Browser caching headers
- CDN integration ready

### Backend
- Cold start optimization
- Connection pooling
- Error handling and retries
- Monitoring and alerting

## 🧪 Testing

### Backend Tests
```bash
cd backend
python -m pytest tests/ -v
```

### Frontend Testing
- Manual testing checklist
- Cross-browser compatibility
- Mobile responsiveness
- API integration testing

## 🔄 Deployment Strategies

### Blue-Green Deployment
- Function App deployment slots
- Traffic routing control
- Rollback capabilities

### Feature Flags
- Application configuration
- A/B testing capabilities
- Gradual rollout support

## 📝 Customization Guide

### Adding New Skills
1. Update `frontend/src/index.html`
2. Add to appropriate skill category
3. Deploy via Git push

### Modifying API Endpoints
1. Edit `backend/function_app.py`
2. Update routes and logic
3. Test locally before deployment

### Infrastructure Changes
1. Modify `terraform/main.tf`
2. Run `terraform plan` locally
3. Deploy via GitHub Actions

## 🐛 Troubleshooting

### Common Issues

**Function App Cold Starts**
- Monitor Application Insights for performance
- Consider Premium plan for production

**CORS Errors**
- Verify Function App CORS configuration
- Check frontend API URL configuration

**Cosmos DB Connection Issues**
- Verify Key Vault secret access
- Check Managed Identity permissions

### Debugging Commands

```bash
# Check Function App logs
az functionapp log tail --name <function-app-name> --resource-group AzureResumeRG

# Verify Terraform state
terraform show

# Test API endpoints
curl -X GET https://your-function-app.azurewebsites.net/api/visitor
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Cloud Resume Challenge](https://cloudresumechallenge.dev/) by Forrest Brazeal
- Azure Documentation and Examples
- Open source community contributions

## 📞 Support

For questions or issues:
1. Check the [Issues](https://github.com/yourusername/azure-resume/issues) page
2. Review Azure documentation
3. Contact via LinkedIn or email

---

**Built with ☁️ and ❤️ for the Cloud Resume Challenge**