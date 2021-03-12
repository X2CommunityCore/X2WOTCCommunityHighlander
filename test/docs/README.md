# Tests for the documentation tool

One can write a bunch of funky doc lines that would throw the script out of whack
if it wasn't specifically written to handle potentially malformed documentation.

The files in `test_src` and `test_tags` are a mock HL source code to be documented,
but with a bunch of syntax and logic errors; `test_output` has the corresponding output.

You can run in this directory (Powershell)

```ps
python ..\..\.scripts\make_docs.py .\test_src --outdir .\test_output --docsdir .\test_tags --dumpelt .\test_output\CHL_Event_Compiletest.uc | % {$_.replace('\', '/')} | Out-File .\test_output\stdout.log -Encoding ASCII
```

or the `testDocs` VS Code task to generate the output + corresponding stdout log. If there are changes compared to
current git HEAD, check if the changes were intentional.