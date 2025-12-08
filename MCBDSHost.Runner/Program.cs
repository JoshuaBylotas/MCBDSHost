using System;
using System.IO;
using Microsoft.Extensions.Configuration;

namespace MCBDSHost.Runner
{
    class Program
    {
        static void Main(string[] args)
        {
            var config = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false)
                .Build();

            string exePath = config["ExePath"] ?? throw new Exception("ExePath not set in config");
            string logFilePath = config["LogFilePath"] ?? "runner.log";

            var runner = new ExeRunner(exePath, logFilePath);
            runner.Start();

            Console.WriteLine("Runner started. Press Ctrl+C to exit.");
            while (true) System.Threading.Thread.Sleep(1000);
        }
    }
}
