using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;

[assembly: AssemblyTitle("Minecraft Bedrock Unlocker")]
[assembly: AssemblyDescription("Launcher wrapper for the embedded install.ps1")]
[assembly: AssemblyCompany("CoelhoFZ")]
[assembly: AssemblyProduct("MinecraftBedrockUnlocker")]
[assembly: AssemblyCopyright("GPLv3")]
[assembly: AssemblyVersion("3.1.6.0")]
[assembly: AssemblyFileVersion("3.1.6.0")]

internal static class Program
{
    private const string ResourceName = "MinecraftBedrockUnlocker.Payload.install.ps1";

    [STAThread]
    private static int Main(string[] args)
    {
        string tempDir = Path.Combine(Path.GetTempPath(), "MinecraftBedrockUnlocker", Guid.NewGuid().ToString("N"));
        string scriptPath = Path.Combine(tempDir, "install.ps1");

        try
        {
            Directory.CreateDirectory(tempDir);
            ExtractEmbeddedScript(scriptPath);

            string shellPath = ResolvePowerShellPath();
            if (string.IsNullOrEmpty(shellPath))
            {
                Console.Error.WriteLine("PowerShell was not found on this system.");
                return 1;
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = shellPath,
                Arguments = BuildPowerShellArguments(scriptPath, args),
                UseShellExecute = false,
                RedirectStandardInput = false,
                RedirectStandardOutput = false,
                RedirectStandardError = false,
                WorkingDirectory = ResolveWorkingDirectory()
            };

            using (Process process = Process.Start(startInfo))
            {
                if (process == null)
                {
                    Console.Error.WriteLine("Failed to start PowerShell.");
                    return 1;
                }

                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
        finally
        {
            TryDelete(scriptPath);
            TryDeleteDirectory(tempDir);
        }
    }

    private static void ExtractEmbeddedScript(string destinationPath)
    {
        Assembly assembly = Assembly.GetExecutingAssembly();
        using (Stream stream = assembly.GetManifestResourceStream(ResourceName))
        {
            if (stream == null)
            {
                throw new InvalidOperationException("Embedded PowerShell payload was not found.");
            }

            using (var reader = new StreamReader(stream, Encoding.UTF8, true))
            {
                string content = reader.ReadToEnd();
                File.WriteAllText(destinationPath, content, new UTF8Encoding(false));
            }
        }
    }

    private static string ResolvePowerShellPath()
    {
        string systemRoot = Environment.GetEnvironmentVariable("SystemRoot");
        if (!string.IsNullOrWhiteSpace(systemRoot))
        {
            string windowsPowerShell = Path.Combine(systemRoot, "System32", "WindowsPowerShell", "v1.0", "powershell.exe");
            if (File.Exists(windowsPowerShell))
            {
                return windowsPowerShell;
            }
        }

        string path = Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
        foreach (string entry in path.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
        {
            try
            {
                string candidate = Path.Combine(entry.Trim(), "pwsh.exe");
                if (File.Exists(candidate))
                {
                    return candidate;
                }
            }
            catch
            {
            }
        }

        return null;
    }

    private static string BuildPowerShellArguments(string scriptPath, string[] args)
    {
        var builder = new StringBuilder();
        builder.Append("-NoLogo -NoProfile -ExecutionPolicy Bypass -File ");
        builder.Append(Quote(scriptPath));

        if (args != null)
        {
            foreach (string arg in args)
            {
                builder.Append(' ');
                builder.Append(Quote(arg ?? string.Empty));
            }
        }

        return builder.ToString();
    }

    private static string ResolveWorkingDirectory()
    {
        string location = Assembly.GetExecutingAssembly().Location;
        string directory = Path.GetDirectoryName(location);
        return string.IsNullOrWhiteSpace(directory) ? Environment.CurrentDirectory : directory;
    }

    private static string Quote(string value)
    {
        if (string.IsNullOrEmpty(value))
        {
            return "\"\"";
        }

        if (value.IndexOfAny(new[] { ' ', '\t', '"' }) == -1)
        {
            return value;
        }

        return "\"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
    }

    private static void TryDelete(string path)
    {
        try
        {
            if (!string.IsNullOrWhiteSpace(path) && File.Exists(path))
            {
                File.Delete(path);
            }
        }
        catch
        {
        }
    }
    private static void TryDeleteDirectory(string path)
    {
        try
        {
            if (!string.IsNullOrWhiteSpace(path) && Directory.Exists(path))
            {
                Directory.Delete(path, true);
            }
        }
        catch
        {
        }
    }

}
