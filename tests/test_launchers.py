"""Exercise launcher behavior without a container engine or model credentials."""

import json
import os
from pathlib import Path
import pty
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
ENGINE = """#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

args = sys.argv[1:]
if args[0] == '--version':
    print('Docker version 27.0.0')
elif args[0] == 'image':
    print('[entrypoint.sh]')
elif args[0] in ('run', 'build'):
    stdin = sys.stdin.read() if args[0] == 'run' and not os.isatty(0) else None
    Path(os.environ['LAUNCHER_CAPTURE']).write_text(json.dumps({'args': args, 'stdin': stdin}))
    sys.exit(int(os.environ.get('LAUNCHER_EXIT_CODE', '0')))
"""


class LauncherChecks:
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.project = self.directory / 'project with spaces'
        self.project.mkdir()
        self.capture = self.directory / 'capture.json'
        self.engine = self.directory / 'container-engine'
        self.engine.write_text(ENGINE)
        self.engine.chmod(0o755)
        # Prevent the launchers from contacting a real token service or using host Git settings.
        for command in ('alcf-tokens', 'git'):
            stub = self.directory / command
            stub.write_text('#!/bin/sh\nexit 1\n')
            stub.chmod(0o755)
        self.environment = {
            'PATH': f'{self.directory}:{Path(sys.executable).parent}:/usr/bin:/bin',
            'CONTAINER_ENGINE': str(self.engine),
            'LAUNCHER_CAPTURE': str(self.capture),
            'IMAGE': 'tutorial:test',
        }

    def launch(self, *args, stdin_terminal=False, stdout_terminal=False, input_text=''):
        self.capture.unlink(missing_ok=True)
        master, slave = pty.openpty()
        try:
            result = subprocess.run(
                [*self.command, *args],
                cwd=self.project,
                env=self.environment,
                stdin=slave if stdin_terminal else None,
                input=None if stdin_terminal else input_text,
                stdout=slave if stdout_terminal else subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=20,
            )
        finally:
            os.close(slave)
            os.close(master)
        self.assertTrue(self.capture.exists(), result.stderr)
        return result, json.loads(self.capture.read_text())

    def test_terminal_is_allocated_only_when_input_and_output_are_terminals(self):
        for stdin_terminal, stdout_terminal in ((False, False), (False, True), (True, False), (True, True)):
            with self.subTest(stdin_terminal=stdin_terminal, stdout_terminal=stdout_terminal):
                result, capture = self.launch(
                    'cat', stdin_terminal=stdin_terminal, stdout_terminal=stdout_terminal,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                args = capture['args']
                self.assertTrue(any(flag in args for flag in ('-i', '-it', '-ti')))
                has_terminal = any(flag in args for flag in ('-t', '-it', '-ti'))
                self.assertEqual(has_terminal, stdin_terminal and stdout_terminal)

    def test_pipe_preserves_stdin_arguments_mount_and_exit_status(self):
        self.environment['LAUNCHER_EXIT_CODE'] = '17'
        result, capture = self.launch('sh', '-c', 'cat; exit 17', input_text='a piped prompt\n')
        self.assertEqual(result.returncode, 17, result.stderr)
        self.assertEqual(capture['stdin'], 'a piped prompt\n')
        self.assertEqual(capture['args'][-4:], ['tutorial:test', 'sh', '-c', 'cat; exit 17'])
        self.assertIn(f'{self.project}:/workspace', capture['args'])

    def test_editor_keeps_localhost_binding_and_forwards_options(self):
        self.environment['PORT'] = '8081'
        result, capture = self.launch('code', '--disable-workspace-trust')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('127.0.0.1:8081:8080', capture['args'])
        self.assertEqual(capture['args'][-2:], ['--disable-workspace-trust', '/workspace'])

    def test_build_uses_repository_directory_and_preserves_exit_status(self):
        self.environment['LAUNCHER_EXIT_CODE'] = '19'
        result, capture = self.launch('build')
        self.assertEqual(result.returncode, 19, result.stderr)
        self.assertEqual(capture['args'], ['build', '-t', 'tutorial:test', str(ROOT)])


class BashLauncherTests(LauncherChecks, unittest.TestCase):
    command = ['bash', str(ROOT / 'run.sh')]


@unittest.skipUnless(shutil.which('pwsh'), 'PowerShell is not installed')
class PowerShellLauncherTests(LauncherChecks, unittest.TestCase):
    command = [shutil.which('pwsh'), '-NoProfile', '-File', str(ROOT / 'run.ps1')]

    def test_interactive_powershell_command_keeps_a_terminal(self):
        script = str(ROOT / 'run.ps1').replace("'", "''")
        self.command = [
            self.command[0], '-NoProfile', '-Command', f"& '{script}' cat; exit $LASTEXITCODE",
        ]
        result, capture = self.launch(stdin_terminal=True, stdout_terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('-t', capture['args'])

    def test_powershell_pipeline_forwards_input_without_a_terminal(self):
        self.environment['LAUNCHER_EXIT_CODE'] = '17'
        script = str(ROOT / 'run.ps1').replace("'", "''")
        self.command = [
            self.command[0], '-NoProfile', '-Command',
            f"'a piped prompt' | & '{script}' cat; exit $LASTEXITCODE",
        ]
        result, capture = self.launch(stdin_terminal=True, stdout_terminal=True)
        self.assertEqual(result.returncode, 17, result.stderr)
        self.assertEqual(capture['stdin'], 'a piped prompt\n')
        self.assertNotIn('-t', capture['args'])

    def test_powershell_output_pipeline_does_not_allocate_a_terminal(self):
        script = str(ROOT / 'run.ps1').replace("'", "''")
        self.command = [
            self.command[0], '-NoProfile', '-Command',
            f"& '{script}' python3 --version | Out-Null; exit $LASTEXITCODE",
        ]
        result, capture = self.launch(stdin_terminal=True, stdout_terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('-t', capture['args'])

    def test_powershell_file_redirection_does_not_allocate_a_terminal(self):
        script = str(ROOT / 'run.ps1').replace("'", "''")
        output = str(self.directory / 'output.txt').replace("'", "''")
        for redirect in ('>', '>>', '*>'):
            with self.subTest(redirect=redirect):
                self.command = [
                    self.command[0], '-NoProfile', '-Command',
                    f"& '{script}' python3 --version {redirect} '{output}'; exit $LASTEXITCODE",
                ]
                result, capture = self.launch(stdin_terminal=True, stdout_terminal=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn('-t', capture['args'])

    def test_powershell_pipeline_streams_before_producer_finishes(self):
        # The producer waits for the engine to acknowledge its first line. Buffering
        # until the producer finishes would deadlock instead of passing this handshake.
        self.environment['LAUNCHER_EXIT_CODE'] = '17'
        self.engine.write_text(ENGINE.replace(
            "stdin = sys.stdin.read() if args[0] == 'run' and not os.isatty(0) else None",
            "first = sys.stdin.readline()\n"
            "    Path(os.environ['LAUNCHER_CAPTURE'] + '.ready').touch()\n"
            "    stdin = first + sys.stdin.read()",
        ))
        script = str(ROOT / 'run.ps1').replace("'", "''")
        ready = str(self.capture) + '.ready'
        self.command = [
            self.command[0], '-NoProfile', '-Command',
            f"& {{ 'first'; $deadline = [DateTime]::UtcNow.AddSeconds(5); "
            f"while (-not (Test-Path '{ready}')) {{ "
            "if ([DateTime]::UtcNow -gt $deadline) { throw 'Input was buffered' }; "
            "Start-Sleep -Milliseconds 20 }; 'second' } "
            f"| & '{script}' cat; exit $LASTEXITCODE",
        ]
        result, capture = self.launch()
        self.assertEqual(result.returncode, 17, result.stderr)
        self.assertNotIn('Input was buffered', result.stderr)
        self.assertEqual(capture['stdin'], 'first\nsecond\n')

    def test_powershell_quoted_redirect_and_stderr_file_keep_terminal(self):
        script = str(ROOT / 'run.ps1').replace("'", "''")
        output = str(self.directory / 'stderr.txt').replace("'", "''")
        self.command = [
            self.command[0], '-NoProfile', '-Command',
            f"& '{script}' echo 'a > b' 2> '{output}'; exit $LASTEXITCODE",
        ]
        result, capture = self.launch(stdin_terminal=True, stdout_terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('-t', capture['args'])
        self.assertEqual(capture['args'][-2:], ['echo', 'a > b'])


if __name__ == '__main__':
    unittest.main()
