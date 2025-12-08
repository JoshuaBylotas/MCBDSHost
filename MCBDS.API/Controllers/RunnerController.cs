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
    }
}
