using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    /// <summary>
    /// Controller for handling AI chat functionality
    /// </summary>
    public class ChatController : Controller
    {
        private readonly ChatService _chatService;
        private readonly ILogger<ChatController> _logger;

        public ChatController(ChatService chatService, ILogger<ChatController> logger)
        {
            _chatService = chatService;
            _logger = logger;
        }

        /// <summary>
        /// Displays the chat interface
        /// </summary>
        public IActionResult Index()
        {
            _logger.LogInformation("Chat page accessed");
            return View();
        }

        /// <summary>
        /// Handles chat message submission
        /// </summary>
        /// <param name="message">The user's message</param>
        /// <returns>JSON response with AI's reply</returns>
        [HttpPost]
        public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request?.Message))
                {
                    _logger.LogWarning("Empty message received");
                    return BadRequest(new { error = "Message cannot be empty" });
                }

                // Sanitize input
                var sanitizedMessage = request.Message.Trim();
                
                if (sanitizedMessage.Length > 1000)
                {
                    _logger.LogWarning("Message too long: {Length} characters", sanitizedMessage.Length);
                    return BadRequest(new { error = "Message is too long. Maximum 1000 characters allowed." });
                }

                _logger.LogInformation("Processing chat message");

                // Get response from Azure OpenAI
                var response = await _chatService.GetChatResponseAsync(sanitizedMessage);

                return Json(new { response });
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogError(ex, "Error processing chat message");
                return StatusCode(500, new { error = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Unexpected error in chat endpoint");
                return StatusCode(500, new { error = "An unexpected error occurred. Please try again later." });
            }
        }
    }

    /// <summary>
    /// Request model for chat messages
    /// </summary>
    public class ChatRequest
    {
        public string Message { get; set; } = string.Empty;
    }
}
