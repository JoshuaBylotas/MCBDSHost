using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.DependencyInjection;
using MCBDS.API.Background;

namespace MCBDS.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RunnerController : ControllerBase
    {
        private readonly RunnerHostedService _runnerService;

        public RunnerController(RunnerHostedService runnerService)
        {
            _runnerService = runnerService;
        }

        [HttpGet("log")]
        public IActionResult GetLog()
        {
            var log = _runnerService.GetLog();
            return Ok(log);
        }

        [HttpGet("status")]
        public IActionResult GetStatus()
        {
            var serverStatus = _runnerService.GetServerStatus();
            var apiStatus = RunnerHostedService.GetApiHostStatus();

            return Ok(new
            {
                server = serverStatus,
                api = apiStatus,
                timestamp = DateTime.UtcNow
            });
        }

        [HttpPost("send")]
        public async Task<IActionResult> SendLine([FromBody] SendLineRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Line))
                return BadRequest("Line cannot be empty.");
            var response = await _runnerService.SendLineAndReadResponseAsync(request.Line);
            if (response != null)
                return Ok(response);
            return StatusCode(503, "Bedrock process is not running, could not accept input, or no response was received in time.");
        }

        [HttpPost("restart")]
        public async Task<IActionResult> Restart()
        {
            var result = await _runnerService.RestartProcessAsync();
            if (result)
                return Ok("Process restarted.");
            return StatusCode(500, "Failed to restart process.");
        }

        public class SendLineRequest
        {
            public string? Line { get; set; }
        }
    }
}


