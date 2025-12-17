using Azure;
using Azure.AI.OpenAI;
using Azure.AI.ContentSafety;
using Azure.Identity;
using OpenAI.Chat;

namespace ZavaStorefront.Services
{
    /// <summary>
    /// Service for handling Azure OpenAI chat interactions
    /// </summary>
    public class ChatService
    {
        private readonly AzureOpenAIClient _openAiClient;
        private readonly ContentSafetyClient _contentSafetyClient;
        private readonly string _deploymentName;
        private readonly ILogger<ChatService> _logger;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _logger = logger;

            // Get Azure OpenAI endpoint from configuration
            var endpoint = configuration["AZURE_OPENAI_ENDPOINT"] 
                ?? throw new InvalidOperationException("AZURE_OPENAI_ENDPOINT environment variable is not set");

            // Get deployment name (defaults to gpt-4o-mini for cost-effective responses)
            _deploymentName = configuration["AZURE_OPENAI_DEPLOYMENT_NAME"] ?? "gpt-4o-mini";

            _logger.LogInformation("Initializing ChatService with endpoint: {Endpoint}, deployment: {Deployment}", 
                endpoint, _deploymentName);

            // Check if API key is provided (for local development)
            var apiKey = configuration["AZURE_OPENAI_API_KEY"];
            if (!string.IsNullOrEmpty(apiKey))
            {
                _logger.LogInformation("Using API key authentication");
                _openAiClient = new AzureOpenAIClient(new Uri(endpoint), new Azure.AzureKeyCredential(apiKey));
                _contentSafetyClient = new ContentSafetyClient(new Uri(endpoint), new Azure.AzureKeyCredential(apiKey));
            }
            else
            {
                _logger.LogInformation("Using DefaultAzureCredential (Managed Identity)");
                // Use DefaultAzureCredential for authentication (supports Managed Identity in Azure)
                var credential = new DefaultAzureCredential();
                _openAiClient = new AzureOpenAIClient(new Uri(endpoint), credential);
                _contentSafetyClient = new ContentSafetyClient(new Uri(endpoint), credential);
            }
        }

        /// <summary>
        /// Sends a message to Azure OpenAI and returns the response
        /// </summary>
        /// <param name="userMessage">The user's message</param>
        /// <returns>The AI's response</returns>
        public async Task<string> GetChatResponseAsync(string userMessage)
        {
            try
            {
                // Check content safety first
                var (isSafe, reason) = await CheckContentSafetyAsync(userMessage);
                if (!isSafe)
                {
                    _logger.LogWarning("Unsafe content detected: {Reason}", reason);
                    return "I'm sorry, but I cannot process that message as it may contain inappropriate content. Please rephrase your question.";
                }

                _logger.LogInformation("Sending chat request to Azure OpenAI");

                var chatClient = _openAiClient.GetChatClient(_deploymentName);

                var messages = new List<ChatMessage>
                {
                    new SystemChatMessage("You are a helpful AI assistant for the Zava Storefront. " +
                        "You help customers with product inquiries and general questions. " +
                        "Be friendly, concise, and helpful."),
                    new UserChatMessage(userMessage)
                };

                var chatCompletion = await chatClient.CompleteChatAsync(messages);

                var aiResponse = chatCompletion.Value.Content[0].Text;

                _logger.LogInformation("Successfully received response from Azure OpenAI");

                return aiResponse ?? "I'm sorry, I couldn't generate a response. Please try again.";
            }
            catch (RequestFailedException ex)
            {
                _logger.LogError(ex, "Azure OpenAI request failed: {Message}", ex.Message);
                throw new InvalidOperationException($"Failed to get chat response: {ex.Message}", ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error during chat request: {Message}", ex.Message);
                throw new InvalidOperationException($"An error occurred while processing your request: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Checks if user message is safe using Azure AI Content Safety
        /// </summary>
        /// <param name="text">The text to analyze</param>
        /// <returns>Tuple of (isSafe, reason)</returns>
        private async Task<(bool isSafe, string reason)> CheckContentSafetyAsync(string text)
        {
            try
            {
                _logger.LogInformation("Checking content safety");

                var request = new AnalyzeTextOptions(text);
                var response = await _contentSafetyClient.AnalyzeTextAsync(request);

                var result = response.Value;

                // Check all categories with severity >= 2
                if (result.CategoriesAnalysis.Any(c => c.Category == TextCategory.Hate && c.Severity >= 2))
                {
                    _logger.LogWarning("Content flagged: Hate");
                    return (false, "hate speech");
                }
                if (result.CategoriesAnalysis.Any(c => c.Category == TextCategory.SelfHarm && c.Severity >= 2))
                {
                    _logger.LogWarning("Content flagged: Self-harm");
                    return (false, "self-harm");
                }
                if (result.CategoriesAnalysis.Any(c => c.Category == TextCategory.Sexual && c.Severity >= 2))
                {
                    _logger.LogWarning("Content flagged: Sexual content");
                    return (false, "sexual content");
                }
                if (result.CategoriesAnalysis.Any(c => c.Category == TextCategory.Violence && c.Severity >= 2))
                {
                    _logger.LogWarning("Content flagged: Violence");
                    return (false, "violence");
                }

                _logger.LogInformation("Content passed safety check");
                return (true, string.Empty);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Content safety check failed: {Message}", ex.Message);
                // On error, allow the message through but log the issue
                return (true, string.Empty);
            }
        }

        /// <summary>
        /// Validates that the chat service is properly configured
        /// </summary>
        public bool IsConfigured()
        {
            return !string.IsNullOrEmpty(_deploymentName);
        }
    }
}
