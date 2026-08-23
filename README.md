# Serverless Infrastructure on AWS

Hello and welcome to my Project. I will preface by saying this, "This is not just a visitor counter on the exterior."

As we dive deeper into the architecture, the real work is a private S3 bucket secured with Cloudfront and OAC (Origin Access Control), a severless REST API built with Lambda and API Gateway. A DynamoDB backend- all connected by applying least-privilege IAM policies and provisioned through Terraform.  

<br>

[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Serverless](https://img.shields.io/badge/Serverless-FD5750?style=for-the-badge&logo=serverless&logoColor=white)](https://www.serverless.com/)
[![CloudFront](https://img.shields.io/badge/CloudFront-FF9900?style=for-the-badge&logo=amazon-cloudfront&logoColor=white)](https://aws.amazon.com/cloudfront/)
[![Lambda](https://img.shields.io/badge/Lambda-FF9900?style=for-the-badge&logo=aws-lambda&logoColor=white)](https://aws.amazon.com/lambda/)
[![DynamoDB](https://img.shields.io/badge/DynamoDB-4053D6?style=for-the-badge&logo=amazon-dynamodb&logoColor=white)](https://aws.amazon.com/dynamodb/)

<br>

**Live Demo:** https://dczebdn2hrm2o.cloudfront.net

<p align="center">
  <img src="screenshot.png" width="80%" alt="Screenshot" />
  <br>
  <em>Screenshot of my website.</em>
</p>

---

## Architecture

- **Frontend:** S3 + CloudFront (HTTPS, global CDN, private origin)
- **Backend:** Lambda (Python) + API Gateway
- **Database:** DynamoDB
- **Security:** CloudFront OAC, IAM least privilege, private S3

---

## How It Works

1. User visits the website.
2. JavaScript in the frontend sends a request to the API Gateway endpoint to fetch the current visitor count.
3. Lambda function reads visitor count from DynamoDB, increments it, and saves it.
4. Updated count is returned and displayed on the page.

---

## Tech Stack

- AWS (S3, CloudFront, Lambda, API Gateway, DynamoDB, IAM)
- Python 3.12
- HTML / CSS / JavaScript
- Git & GitHub
- Terraform

---

## Author

**Aladdin Ali**  
[LinkedIn](https://linkedin.com/in/aladdin-ali) | [GitHub](https://github.com/aladdinali0)
