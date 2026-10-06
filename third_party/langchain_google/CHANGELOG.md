## 0.7.1+2

 - Update a dependency to the latest release.

## 0.7.1+1

 - Update a dependency to the latest release.

## 0.7.1

 - **FIX**(langchain_google): Remove ServiceAccountCredentials stub export ([#838](https://github.com/davidmigloz/langchain_dart/issues/838)). ([d0a058b3](https://github.com/davidmigloz/langchain_dart/commit/d0a058b3f5488470362564fa84c350bdb7b41b14))
 - **FIX**(langchain_google): Add web platform compatibility for HttpClientAuthProvider ([#832](https://github.com/davidmigloz/langchain_dart/issues/832)). ([3a9e995b](https://github.com/davidmigloz/langchain_dart/commit/3a9e995b6dc75fe403175f6183c04387b6aa4e03))
 - **FEAT**: Add listModels() API for LLMs and Embeddings ([#371](https://github.com/davidmigloz/langchain_dart/issues/371)) ([#844](https://github.com/davidmigloz/langchain_dart/issues/844)). ([4b737389](https://github.com/davidmigloz/langchain_dart/commit/4b7373894d5b8701b6d00d153c1741931a49b3a1))

## 0.7.0+1

 - **REFACTOR**: Fix pub format warnings ([#809](https://github.com/davidmigloz/langchain_dart/issues/809)). ([640cdefb](https://github.com/davidmigloz/langchain_dart/commit/640cdefbede9c0a0182fb6bb4005a20aa6f35635))

## 0.7.0

> Note: This release has breaking changes.

 - **REFACTOR**: Migrate langchain_google to the new googleai_dart client ([#788](https://github.com/davidmigloz/langchain_dart/issues/788)). ([f28edec9](https://github.com/davidmigloz/langchain_dart/commit/f28edec9206450d753db181f8af254df339d8290))
 - **FEAT**: Upgrade to http v1.5.0 ([#785](https://github.com/davidmigloz/langchain_dart/issues/785)). ([f7c87790](https://github.com/davidmigloz/langchain_dart/commit/f7c8779011015b5a4a7f3a07dca32bde1bb2ea88))
 - **BREAKING** **BUILD**: Require Dart >=3.8.0 ([#792](https://github.com/davidmigloz/langchain_dart/issues/792)). ([b887f5c6](https://github.com/davidmigloz/langchain_dart/commit/b887f5c62e307b3a510c5049e3d1fbe7b7b4f4c9))

## NEXT

 - **BREAKING**: Migrated from deprecated `google_generative_ai` to `googleai_dart` package
   - Updated ChatGoogleGenerativeAI to use the new googleai_dart client with resource-based API structure
   - Updated GoogleGenerativeAIEmbeddings to use the new googleai_dart client with synchronous batch embeddings API and resource-based structure
   - API calls now use resource organization (e.g., `client.models.generateContent()` instead of `client.generateContent()`)
   - Changed default embeddings model to `gemini-embedding-001` (recommended stable model)
   - Removed CustomHttpClient utility (replaced by GoogleAIConfig)
   - Restored support for reduced dimensionality via `dimensions` parameter
 - **FEAT**: Added support for `presencePenalty`, `frequencyPenalty`, and `cachedContent` parameters in ChatGoogleGenerativeAIOptions
 - **DOCS**: Updated model documentation to include Gemini 2.5 series models (gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite)
 - **DOCS**: Added documentation for embeddings models including gemini-embedding-001 and flexible dimensions support
 - **FIX**: Improved error handling in embeddings batch API with specific fallback for model field validation errors

## 0.6.5+2

 - **FIX**: Batch sequential tool responses in GoogleAI & Firebase VertexAI ([#757](https://github.com/davidmigloz/langchain_dart/issues/757)). ([8ff44486](https://github.com/davidmigloz/langchain_dart/commit/8ff4448665d26b49c1e1077d0822703e7d853d39))

## 0.6.5+1

 - **BUILD**: Update dependencies ([#751](https://github.com/davidmigloz/langchain_dart/issues/751)). ([250a3c6](https://github.com/davidmigloz/langchain_dart/commit/250a3c6a6c1815703a61a142ba839c0392a31015))

## 0.6.5

 - **FEAT**: Update dependencies (requires Dart 3.6.0) ([#709](https://github.com/davidmigloz/langchain_dart/issues/709)). ([9e3467f7](https://github.com/davidmigloz/langchain_dart/commit/9e3467f7caabe051a43c0eb3c1110bc4a9b77b81))
 - **REFACTOR**: Remove fetch_client dependency in favor of http v1.3.0 ([#659](https://github.com/davidmigloz/langchain_dart/issues/659)). ([0e0a685c](https://github.com/davidmigloz/langchain_dart/commit/0e0a685c376895425dbddb0f9b83758c700bb0c7))
 - **FIX**: Fix linter issues ([#656](https://github.com/davidmigloz/langchain_dart/issues/656)). ([88a79c65](https://github.com/davidmigloz/langchain_dart/commit/88a79c65aad23bcf5859e58a7375a4b686cf02ef))

## 0.6.4+2

 - **REFACTOR**: Add new lint rules and fix issues ([#621](https://github.com/davidmigloz/langchain_dart/issues/621)). ([60b10e00](https://github.com/davidmigloz/langchain_dart/commit/60b10e008acf55ebab90789ad08d2449a44b69d8))

## 0.6.4+1

 - **FIX**: UUID 'Namespace' can't be assigned to the parameter type 'String?' ([#566](https://github.com/davidmigloz/langchain_dart/issues/566)). ([1e93a595](https://github.com/davidmigloz/langchain_dart/commit/1e93a595f2f166da2cae3f7cfcdbb28892abf9b5))

## 0.6.4

 - **FEAT**: Add support for code execution in ChatGoogleGenerativeAI ([#564](https://github.com/davidmigloz/langchain_dart/issues/564)). ([020bc096](https://github.com/davidmigloz/langchain_dart/commit/020bc096e2bb83bd372d0568a111481df188a7f2))

## 0.6.3+1

 - **FEAT**: Add support for reduced output dimensionality in GoogleGenerativeAIEmbeddings ([#544](https://github.com/davidmigloz/langchain_dart/issues/544)). ([d5880704](https://github.com/davidmigloz/langchain_dart/commit/d5880704c492889144738acffd49674b91e63981))
 - **DOCS**: Update Google's models in documentation ([#551](https://github.com/davidmigloz/langchain_dart/issues/551)). ([1da543f7](https://github.com/davidmigloz/langchain_dart/commit/1da543f7ab90eb39b599a6fdd0cc52e2cbc1460d))

## 0.6.2

 - **FEAT**: Add copyWith method to all RunnableOptions subclasses ([#531](https://github.com/davidmigloz/langchain_dart/issues/531)). ([42c8d480](https://github.com/davidmigloz/langchain_dart/commit/42c8d480041e7ca331e4928c46536037c06dbff0))

## 0.6.1

 - **FEAT**: Implement additive options merging for cascade bind calls ([#500](https://github.com/davidmigloz/langchain_dart/issues/500)). ([8691eb21](https://github.com/davidmigloz/langchain_dart/commit/8691eb21d5d2ffbf853997cbc0eaa29a56c6ca43))
 - **REFACTOR**: Remove default model from the language model options ([#498](https://github.com/davidmigloz/langchain_dart/issues/498)). ([44363e43](https://github.com/davidmigloz/langchain_dart/commit/44363e435778282ed27bc1b2771cf8b25abc7560))
 - **REFACTOR**: Depend on exact versions for internal 1st party dependencies ([#484](https://github.com/davidmigloz/langchain_dart/issues/484)). ([244e5e8f](https://github.com/davidmigloz/langchain_dart/commit/244e5e8f30e0d9a642fe01a804cc0de5e807e13d))

## 0.6.0

> Note: `ChatGoogleGenerativeAI` now uses `gemini-1.5-flash` model by default.

 - **BREAKING** **FEAT**: Update ChatGoogleGenerativeAI default model to  gemini-1.5-flash ([#462](https://github.com/davidmigloz/langchain_dart/issues/462)). ([c8b30c90](https://github.com/davidmigloz/langchain_dart/commit/c8b30c906a17751547cc340f987b6670fbd67e69))
 - **FEAT**: Add support for ChatToolChoiceRequired ([#474](https://github.com/davidmigloz/langchain_dart/issues/474)). ([bf324f36](https://github.com/davidmigloz/langchain_dart/commit/bf324f36f645c53458d5891f8285991cd50f2649))
 - **FEAT**: Support response MIME type and schema in ChatGoogleGenerativeAI ([#461](https://github.com/davidmigloz/langchain_dart/issues/461)). ([e258399e](https://github.com/davidmigloz/langchain_dart/commit/e258399e03437e8abe25417a14671dfb719cb273))
 - **REFACTOR**: Migrate conditional imports to js_interop ([#453](https://github.com/davidmigloz/langchain_dart/issues/453)). ([a6a78cfe](https://github.com/davidmigloz/langchain_dart/commit/a6a78cfe05fb8ce68e683e1ad4395ca86197a6c5))

## 0.5.1

 - **FEAT**: Add Runnable.close() to close any resources associated with it ([#439](https://github.com/davidmigloz/langchain_dart/issues/439)). ([4e08cced](https://github.com/davidmigloz/langchain_dart/commit/4e08cceda964921178061e9721618a1505198ff5))

## 0.5.0

> Note: `ChatGoogleGenerativeAI` and `GoogleGenerativeAIEmbeddings` now use the version `v1beta` of the Gemini API (instead of `v1`) which support the latest models (`gemini-1.5-pro-latest` and `gemini-1.5-flash-latest`).
> 
> VertexAI for Firebase (`ChatFirebaseVertexAI`) is available in the new [`langchain_firebase`](https://pub.dev/packages/langchain_firebase) package.

 - **FEAT**: Add support for tool calling in ChatGoogleGenerativeAI ([#419](https://github.com/davidmigloz/langchain_dart/issues/419)). ([df41f38a](https://github.com/davidmigloz/langchain_dart/commit/df41f38aab64651a06a42fc41d9c35f33250a3e9))
 - **DOCS**: Add Gemini 1.5 Flash to models list ([#423](https://github.com/davidmigloz/langchain_dart/issues/423)). ([40f4c9de](https://github.com/davidmigloz/langchain_dart/commit/40f4c9de9c25804e298fd481c80f8c52d53302fb))
 - **BREAKING** **FEAT**: Migrate internal client from googleai_dart to google_generative_ai ([#407](https://github.com/davidmigloz/langchain_dart/issues/407)). ([fa4b5c37](https://github.com/davidmigloz/langchain_dart/commit/fa4b5c376a191fea50c3f8b1d6b07cef0480a74e))

## 0.4.0

> Note: This release has breaking changes.  
> If you are using "function calling" check [how to migrate to "tool calling"](https://github.com/davidmigloz/langchain_dart/issues/400).

 - **BREAKING** **FEAT**: Migrate from function calling to tool calling ([#400](https://github.com/davidmigloz/langchain_dart/issues/400)). ([44413b83](https://github.com/davidmigloz/langchain_dart/commit/44413b8321b1188ff6b4027b1972a7ee0002761e))

## 0.3.0+2

 - Update a dependency to the latest release.

## 0.3.0+1

 - Update a dependency to the latest release.

## 0.3.0

> Note: This release has breaking changes.  
> [Migration guide](https://github.com/davidmigloz/langchain_dart/discussions/374)

 - **BREAKING** **REFACTOR**: Introduce langchain_core and langchain_community packages ([#328](https://github.com/davidmigloz/langchain_dart/issues/328)). ([5fa520e6](https://github.com/davidmigloz/langchain_dart/commit/5fa520e663602d9cdfcab0c62a053090fa02b02e))
 - **BREAKING** **REFACTOR**: Simplify LLMResult and ChatResult classes ([#363](https://github.com/davidmigloz/langchain_dart/issues/363)). ([ffe539c1](https://github.com/davidmigloz/langchain_dart/commit/ffe539c13f92cce5f564107430163b44be1dfd96))
 - **BREAKING** **REFACTOR**: Simplify Output Parsers ([#367](https://github.com/davidmigloz/langchain_dart/issues/367)). ([f24b7058](https://github.com/davidmigloz/langchain_dart/commit/f24b7058949fba47ba624f071a3f548b8f6e915e))
 - **BREAKING** **REFACTOR**: Remove deprecated generate and predict APIs ([#335](https://github.com/davidmigloz/langchain_dart/issues/335)). ([c55fe50f](https://github.com/davidmigloz/langchain_dart/commit/c55fe50f0040cc04cbd2e90bca475887c093c654))
 - **REFACTOR**: Simplify internal .stream implementation ([#364](https://github.com/davidmigloz/langchain_dart/issues/364)). ([c83fed22](https://github.com/davidmigloz/langchain_dart/commit/c83fed22b2b89d5e51211984b12ec126a3ca225e))
 - **FEAT**: Implement .batch support ([#370](https://github.com/davidmigloz/langchain_dart/issues/370)). ([d254f929](https://github.com/davidmigloz/langchain_dart/commit/d254f929b03d9c950029e55c66831f9f89cc14a9))
 - **FEAT**: Add streaming support in ChatGoogleGenerativeAI ([#360](https://github.com/davidmigloz/langchain_dart/issues/360)). ([68bfdb04](https://github.com/davidmigloz/langchain_dart/commit/68bfdb04e417a7023b8872cbe0798243503fbf3d))
 - **FEAT**: Support tuned models in ChatGoogleGenerativeAI ([#359](https://github.com/davidmigloz/langchain_dart/issues/359)). ([764b633d](https://github.com/davidmigloz/langchain_dart/commit/764b633df1412f53fc238afe1e97d1e1ac22f206))
 - **FEAT**: Add support for GoogleGenerativeAIEmbeddings ([#362](https://github.com/davidmigloz/langchain_dart/issues/362)). ([d4f888a0](https://github.com/davidmigloz/langchain_dart/commit/d4f888a0e347608f0538d656d0c5507b61e5ee7e))
 - **FEAT**: Support output dimensionality in GoogleGenerativeAIEmbeddings ([#373](https://github.com/davidmigloz/langchain_dart/issues/373)). ([6dcb27d8](https://github.com/davidmigloz/langchain_dart/commit/6dcb27d861fa65d2c882e31ce28e8c0a92b65cc1))
 - **FEAT**: Support updating API key in Google AI client ([#357](https://github.com/davidmigloz/langchain_dart/issues/357)). ([b9b808e7](https://github.com/davidmigloz/langchain_dart/commit/b9b808e72f02b9f38ab355d581284a0d848d4bd1))

## 0.2.4

 - **FEAT**: Update meta and test dependencies ([#331](https://github.com/davidmigloz/langchain_dart/issues/331)). ([912370ee](https://github.com/davidmigloz/langchain_dart/commit/912370ee0ba667ee9153303395a457e6caf5c72d))
 - **DOCS**: Update pubspecs. ([d23ed89a](https://github.com/davidmigloz/langchain_dart/commit/d23ed89adf95a34a78024e2f621dc0af07292f44))

## 0.2.3+3

 - **DOCS**: Update CHANGELOG.md. ([d0d46534](https://github.com/davidmigloz/langchain_dart/commit/d0d46534565d6f52d819d62329e8917e00bc7030))

## 0.2.3+2

 - Update a dependency to the latest release.

## 0.2.3+1

 - **REFACTOR**: Remove tiktoken in favour of countTokens API on VertexAI ([#307](https://github.com/davidmigloz/langchain_dart/issues/307)). ([8158572b](https://github.com/davidmigloz/langchain_dart/commit/8158572b15c0525b9caa9bc71fbbbee6ab4458fe))

## 0.2.3

 - **REFACTOR**: Use cl100k_base encoding model when no tokenizer is available ([#295](https://github.com/davidmigloz/langchain_dart/issues/295)). ([ca908e80](https://github.com/davidmigloz/langchain_dart/commit/ca908e8011a168a74240310c78abb3c590654a49))
 - **REFACTOR**: Make all LLM options fields nullable and add copyWith ([#284](https://github.com/davidmigloz/langchain_dart/issues/284)). ([57eceb9b](https://github.com/davidmigloz/langchain_dart/commit/57eceb9b47da42cf19f64ddd88bfbd2c9676fd5e))
 - **REFACTOR**: Migrate tokenizer to langchain_tiktoken package ([#285](https://github.com/davidmigloz/langchain_dart/issues/285)). ([6a3b6466](https://github.com/davidmigloz/langchain_dart/commit/6a3b6466e3e4cfddda2f506adbf2eb563814d02f))
 - **FEAT**: Update internal dependencies ([#291](https://github.com/davidmigloz/langchain_dart/issues/291)). ([69621cc6](https://github.com/davidmigloz/langchain_dart/commit/69621cc61659980d046518ee20ce055e806cba1f))

## 0.2.2+1

 - Update a dependency to the latest release.

## 0.2.2

 - Update a dependency to the latest release.

## 0.2.1+2

 - Update a dependency to the latest release.

## 0.2.1+1

 - **DOCS**: Update langchain_google README. ([5b2acfa1](https://github.com/davidmigloz/langchain_dart/commit/5b2acfa1667e63774526cb10e9adf53ff8c79530))

## 0.2.1

 - **FEAT**: Add support for ChatGoogleGenerativeAI wrapper (Gemini API) ([#270](https://github.com/davidmigloz/langchain_dart/issues/270)). ([5d006c12](https://github.com/davidmigloz/langchain_dart/commit/5d006c121172192765b1a76582588c05b779e9c0))

## 0.2.0+1

 - Update a dependency to the latest release.

## 0.2.0

> Note: This release has breaking changes.
> 
> Migration guides:
> - [`VertexAI`](https://github.com/davidmigloz/langchain_dart/issues/241)
> - [`ChatVertexAI`](https://github.com/davidmigloz/langchain_dart/issues/242)

 - **BREAKING** **FEAT**: Move all model config options to VertexAIOptions ([#241](https://github.com/davidmigloz/langchain_dart/issues/241)). ([a714882a](https://github.com/davidmigloz/langchain_dart/commit/a714882a3026c7f381b6853d6b61506060b0775e))
 - **BREAKING** **FEAT**: Move all model config options to ChatVertexAIOptions ([#242](https://github.com/davidmigloz/langchain_dart/issues/242)). ([89bef8a2](https://github.com/davidmigloz/langchain_dart/commit/89bef8a22fb0b74ffd9d7a4028c64b2d94d38578))
 - **FEAT**: Allow to mutate default options ([#256](https://github.com/davidmigloz/langchain_dart/issues/256)). ([cb5e4058](https://github.com/davidmigloz/langchain_dart/commit/cb5e4058fb89f33c8495ac22fb240ce92daa683c))

## 0.1.0+4

 - Update a dependency to the latest release.

## 0.1.0+3

 - Update a dependency to the latest release.

## 0.1.0+2

 - Update a dependency to the latest release.

## 0.1.0+1

 - **DOCS**: Add public_member_api_docs lint rule and document missing APIs ([#223](https://github.com/davidmigloz/langchain_dart/issues/223)). ([52380433](https://github.com/davidmigloz/langchain_dart/commit/523804331783970870b023946c016be6c0797920))

## 0.1.0

> Note: This release has breaking changes.  
> [Migration guide](https://github.com/davidmigloz/langchain_dart/issues/220)

 - **BREAKING** **FEAT**: Add multi-modal messages support with OpenAI Vision ([#220](https://github.com/davidmigloz/langchain_dart/issues/220)). ([6da2e069](https://github.com/davidmigloz/langchain_dart/commit/6da2e069932782eed8c27da45c56b4c290373fac))

## 0.0.10+1

 - **DOCS**: Update vector stores documentation. ([dad60d24](https://github.com/davidmigloz/langchain_dart/commit/dad60d247fac157f2980f73c14ac88e9a0894fba))

## 0.0.10

 - **FEAT**: Add result id in ChatVertexAI generations ([#195](https://github.com/davidmigloz/langchain_dart/issues/195)). ([a5bea6d3](https://github.com/davidmigloz/langchain_dart/commit/a5bea6d3aefbb53ed55d3abda0f51f5878445b72))

## 0.0.9

> Note: This release has breaking changes.

 - **DOCS**: Update changelog. ([d45d624a](https://github.com/davidmigloz/langchain_dart/commit/d45d624a0ba12e53c4e78a29750cad30d66c61c5))
 - **BREAKING** **FEAT**: Update uuid internal dependency to 4.x.x ([#173](https://github.com/davidmigloz/langchain_dart/issues/173)). ([b01f4afe](https://github.com/davidmigloz/langchain_dart/commit/b01f4afea6cfcdf8a0aa6e1b11d3057efa6e5fc0))

## 0.0.8

 - Updated `langchain` dependency

## 0.0.7+1

 - **REFACTOR**: Require `http.Client` instead of `AuthClient` ([#156](https://github.com/davidmigloz/langchain_dart/issues/156)). ([0f7fee7f](https://github.com/davidmigloz/langchain_dart/commit/0f7fee7f0780e5b650ec50307a7fda65e242e822))

## 0.0.7

> Note: This release has breaking changes.

 - **FEAT**: Support document title in VertexAIEmbeddings ([#154](https://github.com/davidmigloz/langchain_dart/issues/154)). ([6b763731](https://github.com/davidmigloz/langchain_dart/commit/6b76373139bb50e8d0e59b3f63b54f6adae3d498))
 - **FEAT**: Support task type in VertexAIEmbeddings ([#151](https://github.com/davidmigloz/langchain_dart/issues/151)). ([8a2199e2](https://github.com/davidmigloz/langchain_dart/commit/8a2199e26a945f7d2ad8d3da3ca14e083172f6f1))
 - **DOCS**: Fix invalid package topics. ([f81b833a](https://github.com/davidmigloz/langchain_dart/commit/f81b833aae33e0a945ef4450da12344886224bae))
 - **DOCS**: Add topics to pubspecs. ([8c1d6297](https://github.com/davidmigloz/langchain_dart/commit/8c1d62970710cc326fd5930101918aaf16b18f74))
 - **BREAKING** **REFACTOR**: Change embedDocuments input to `List<Document>` ([#153](https://github.com/davidmigloz/langchain_dart/issues/153)). ([1b5d6fbf](https://github.com/davidmigloz/langchain_dart/commit/1b5d6fbf20bcbb7734581f91d66eff3a86731fec))
 - **BREAKING** **FEAT**: Add default and call options in VertexAI and ChatVertexAI ([#155](https://github.com/davidmigloz/langchain_dart/issues/155)). ([fe1b12ea](https://github.com/davidmigloz/langchain_dart/commit/fe1b12ea282cd587f9dc78bd959741781ebb6d35))

## 0.0.6

 - **DOCS**: Update packages example. ([4f8488fc](https://github.com/davidmigloz/langchain_dart/commit/4f8488fcb324e31b9d8dece7d1999333d7982253))

## 0.0.5

 - **FEAT**: Add support for Chroma VectorStore ([#139](https://github.com/davidmigloz/langchain_dart/issues/139)). ([098783b4](https://github.com/davidmigloz/langchain_dart/commit/098783b4895ab30bb61d07355a0b587ff76b9175))
 - **DOCS**: Fix typos. ([282cfa24](https://github.com/davidmigloz/langchain_dart/commit/282cfa24caa7b91ce28db6b1997af4c2c3ecf3e4))
 - **DOCS**: Update readme. ([b61eda5b](https://github.com/davidmigloz/langchain_dart/commit/b61eda5ba506b4602592511c6a9be1e7aae5bf57))

## 0.0.4

 - **FEAT**: Support filtering in VertexAI Matching Engine ([#136](https://github.com/davidmigloz/langchain_dart/issues/136)). ([768c6987](https://github.com/davidmigloz/langchain_dart/commit/768c6987de5b36b60090a1fe94f49483da11b885))
 - **FEAT**: Allow to pass vector search config ([#135](https://github.com/davidmigloz/langchain_dart/issues/135)). ([5b8fa5a3](https://github.com/davidmigloz/langchain_dart/commit/5b8fa5a3fcaf785615016be1d5da0a003178cfa9))
 - **DOCS**: Fix API documentation errors ([#138](https://github.com/davidmigloz/langchain_dart/issues/138)). ([1aa38fce](https://github.com/davidmigloz/langchain_dart/commit/1aa38fce17eed7f325e7872d03096740256d57be))

## 0.0.3

 - **FEAT**: Infer queryRootUrl in VertexAIMatchingEngine ([#133](https://github.com/davidmigloz/langchain_dart/issues/133)). ([c5353368](https://github.com/davidmigloz/langchain_dart/commit/c5353368d1455756554f6640d33d0b3752476eb9))

## 0.0.2+2

 - Update a dependency to the latest release.

## 0.0.2+1

 - **DOCS**: Add VertexAI Matching Engine sample setup script ([#121](https://github.com/davidmigloz/langchain_dart/issues/121)). ([ed2e1549](https://github.com/davidmigloz/langchain_dart/commit/ed2e1549ca1d6bb0223231bcbe0c1c4a6a198402))

## 0.0.2

 - **FEAT**: Integrate Vertex AI Matching Engine vector store ([#103](https://github.com/davidmigloz/langchain_dart/issues/103)). ([289c3eef](https://github.com/davidmigloz/langchain_dart/commit/289c3eef722206ac9dea0c968c036ad3289d10be))
 - **DOCS**: Update readme. ([a64860ce](https://github.com/davidmigloz/langchain_dart/commit/a64860ceda8fe926b720086cf7c86df2b02abf35))

## 0.0.1

 - **REFACTOR**: Move Vertex AI client to its own package ([#111](https://github.com/davidmigloz/langchain_dart/issues/111)). ([d8aea156](https://github.com/davidmigloz/langchain_dart/commit/d8aea15633f1a9fb0df35cf9cc44bbc93ad46cd8))
 - **FEAT**: Integrate Google Vertex AI PaLM Embeddings ([#100](https://github.com/davidmigloz/langchain_dart/issues/100)). ([d777eccc](https://github.com/davidmigloz/langchain_dart/commit/d777eccc0c81c58b322f28e6e3c4a8763f3f84b7))
 - **FEAT**: Integrate Google Vertex AI PaLM Chat Model ([#99](https://github.com/davidmigloz/langchain_dart/issues/99)). ([3897595d](https://github.com/davidmigloz/langchain_dart/commit/3897595db597d5957ef80ae7a1de35c5f41265b8))
 - **FEAT**: Integrate Google Vertex AI PaLM Text model ([#98](https://github.com/davidmigloz/langchain_dart/issues/98)). ([b2746c23](https://github.com/davidmigloz/langchain_dart/commit/b2746c235d68045ba20afd1f2be7c24dcccb5f24))
 - **FEAT**: Add GCP Vertex AI Model Garden API client ([#109](https://github.com/davidmigloz/langchain_dart/issues/109)). ([5b9bb063](https://github.com/davidmigloz/langchain_dart/commit/5b9bb063a03fb290305fbc0bec502a3c93077583))

## 0.0.1-dev.1

- Bootstrap project.
