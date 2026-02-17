from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.database import Dynamodb
from diagrams.aws.network import APIGateway, Route53
from diagrams.aws.security import CertificateManager, IAMPermissions

with Diagram("Security Agent Demo - Vulnerable Notes API", filename="generated-diagrams/diagram", show=False, direction="LR"):

    dns = Route53("Route 53\nCustom Domain")
    cert = CertificateManager("ACM\nTLS 1.2")

    with Cluster("API Layer"):
        apigw = APIGateway("API Gateway\nRegional HTTP")

    with Cluster("Compute"):
        lam = Lambda("Lambda\nNotes API")

    with Cluster("Data"):
        ddb = Dynamodb("DynamoDB\nNotes")

    with Cluster("AWS Security Agent"):
        sa = IAMPermissions("Security\nAgent")

    dns >> cert >> apigw >> lam >> ddb
    sa >> Edge(color="red", style="dashed", label="design review\ncode review\npentest") >> apigw
