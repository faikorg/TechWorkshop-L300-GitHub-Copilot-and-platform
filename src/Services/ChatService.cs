using Azure;
using Azure.AI.OpenAI;
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

            // Use DefaultAzureCredential for authentication (supports Managed Identity in Azure)
            var credential = new DefaultAzureCredential();
            _openAiClient = new AzureOpenAIClient(new Uri(endpoint), credential);
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
                throw new InvalidOperationException($"Failed to get response from AI service: {ex.Message}", ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in ChatService: {Message}", ex.Message);
                throw new InvalidOperationException("An unexpected error occurred while processing your request.", ex);
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
