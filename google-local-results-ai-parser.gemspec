Gem::Specification.new do |spec|
  spec.name          = "google-local-results-ai-parser"
  spec.version       = "0.2.6"
  spec.summary       = "A gem to be used with serpapi/bert-base-local-results model to predict different parts of Google Local Listings."
  spec.description   = "A gem to be used with serpapi/bert-base-local-results model to predict different parts of Google Local Listings. This gem uses BERT model at https://huggingface.co/serpapi/bert-base-local-results in the background. For serving private servers, head to https://github.com/serpapi/google-local-results-ai-server to get more information."
  spec.homepage      = "https://github.com/serpapi/google-local-results-ai-parser"
  spec.license       = "MIT"
  spec.authors       = ["Emirhan Akdeniz"]
  spec.email         = "kagermanovtalks@gmail.com"
  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]
  spec.add_dependency 'nokolexbor'
  spec.add_dependency 'http'
  spec.add_dependency 'parallel', '~> 1.20', '>= 1.20.1'
  spec.add_dependency 'json'
end
