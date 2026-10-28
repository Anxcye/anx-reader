# 🦜️🔗 LangChain.dart / Google

[![tests](https://img.shields.io/github/actions/workflow/status/davidmigloz/langchain_dart/test.yaml?logo=github&label=tests)](https://github.com/davidmigloz/langchain_dart/actions/workflows/test.yaml)
[![docs](https://img.shields.io/github/actions/workflow/status/davidmigloz/langchain_dart/pages%2Fpages-build-deployment?logo=github&label=docs)](https://github.com/davidmigloz/langchain_dart/actions/workflows/pages/pages-build-deployment)
[![langchain_google](https://img.shields.io/pub/v/langchain_google.svg)](https://pub.dev/packages/langchain_google)
![Discord](https://img.shields.io/discord/1123158322812555295?label=discord)
[![MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://github.com/davidmigloz/langchain_dart/blob/main/LICENSE)

Google module for [LangChain.dart](https://github.com/davidmigloz/langchain_dart).

## Features

- LLMs:
  * `VertexAI`: wrapper around GCP Vertex AI text models API (aka PaLM API for text).
- Chat models:
  * `ChatVertexAI`: wrapper around GCP Vertex AI text chat models API (aka PaLM API for chat).
  * `ChatGoogleGenerativeAI`: wrapper around [Google AI for Developers](https://ai.google.dev) API (Gemini).
- Embeddings:
  * `VertexAIEmbeddings`: wrapper around GCP Vertex AI text embedding models API.
  * `GoogleGenerativeAIEmbeddings` wrapper around [Google AI for Developers](https://ai.google.dev) API (Gemini).
- Vector stores:
  * `VertexAIMatchingEngine` vector store that uses GCP Vertex AI Matching 
    Engine and Cloud Storage.

> Note: VertexAI for Firebase (`ChatFirebaseVertexAI`) is available in the [`langchain_firebase`](https://pub.dev/packages/langchain_firebase) package. 

## License

LangChain.dart is licensed under the
[MIT License](https://github.com/davidmigloz/langchain_dart/blob/main/LICENSE).
