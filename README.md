# StoryCollab
Story Collab is a platform for enabling users to collaboratively help each other with story writing and narration. This platform enables users to publish the story and perform CRUD operations while other users may ask for permission to view your story and gain access to it. Also edit the story. I have made the backend of this platform using golang and gin framework. Used Kubectl for kubernetes connection and pods building for the nodes in node groups of the cluster in AWS EKS. With backend deployment on AWS EKS and docker postgres alpine image to ECR for cluster and node group access. Later we shifted to EC2 micro instances due to charges bound to EKS services. I have used SQLC orm for database queries and schemas for postgres. I have made makefiles for easy data migrations and container and image building for docker. Also docker compose for deploying images to ECR.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
