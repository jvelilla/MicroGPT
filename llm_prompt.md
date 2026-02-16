---
title: LLM prompt — standalone Eiffel project generator
---

Purpose
- Provide a self-contained prompt an LLM can use to generate a new Eiffel project. This prompt does NOT rely on external files — everything needed is described inline.

Placeholders
- `<PROJECT_NAME>` — project directory and ECF name
- `<DESCRIPTION>` — short project description
- `<AUTHOR>` — author name
- `<Eiffel_Version>` — target Eiffel/EiffelStudio version

Required output structure
- `<PROJECT_NAME>/`
  - `src/` (application classes; at least one `APPLICATION` class)
  - `testing/` (AutoTest-style tests; at least one test class)
  - `<PROJECT_NAME>.ecf` (minimal ECF referencing `src` and `testing`)
  - `<PROJECT_NAME>.rc` (optional)
  - `README.md`
  - `.gitignore`

Constraints & expectations for the LLM
- Keep Eiffel source files short and syntactically valid.
- Include a small Design-by-Contract example (pre/post/invariant) in at least one class.
- Provide minimal, valid `.ecf` content that lists `src` and `testing` as source directories.
- Do NOT reference or require any local `templates/` folder — all rules are embedded here.
- Do NOT produce binary content.
- Keep files short enough to paste into a response; include full file contents.

Compilation & CI
See the final section "Command-line compile & test (ec options)" at the end of this prompt for generic `ec` command-line options to compile and run generated projects. Do not rely on PowerShell-specific snippets in the middle of the prompt; compilation details are consolidated at the end.

Prompt output format requirements (how the LLM should respond)
- The LLM must return only the file tree and full contents for each file in the required output structure.
- For each file, include a clear path header followed by the full file contents. Example format:

```
<PROJECT_NAME>/README.md
<full contents here>

<PROJECT_NAME>/src/main.e
<full contents here>

...etc...
```

What NOT to include
- Do NOT include `EIFGENs/` generated build outputs or any binary artifacts.
- Do NOT require or reference the `templates/` folder — the prompt is intended to be standalone.
- Do NOT include a step that *must* create a ZIP file. If packaging is desired, include it as an optional step the user can run locally.

Verification checklist (LLM must ensure these are true)
- **ECF references**: The `.ecf` file includes `src` and `testing` directories.
- **Main class**: The main `APPLICATION` class in `src` prints a short startup message when run.
- **Tests**: The `testing` folder contains at least one test and a test runner that prints a pass/fail summary.
- **Compile steps**: Provide command-line commands (using `ec`/`ec.exe`) to compile the project and run tests.

ECF target naming (important)
- **Target name must match the project name**: The primary build target in the `.ecf` MUST use the literal project name (`<PROJECT_NAME>`) as its `name` attribute (do not use `default` or other generic names). This avoids confusion when invoking `ec -target` and makes generated `.ecf` files consistent.
- **Tests target should extend the project target**: Create a `tests` target that `extends` the `<PROJECT_NAME>` target (or use a `<PROJECT_NAME>-tests` named target that extends `<PROJECT_NAME>`). Ensure the `root` attribute of the tests target points to the test runner class (for example `TEST_APPLICATION`).

Example ECF snippet (recommended):
```xml
<target name="<PROJECT_NAME>">
    <root class="APPLICATION" feature="make"/>
    <cluster name="src" location="./src" recursive="true"/>
</target>

<target name="tests" extends="<PROJECT_NAME>">
    <root class="TEST_APPLICATION" feature="run"/>
    <cluster name="testing" location="./testing" recursive="true"/>
</target>
```

Build command guidance:
- When providing example build commands, always show `-target <PROJECT_NAME>` (not `-target default`). Example:

```text
ec -config <PROJECT_NAME>.ecf -target <PROJECT_NAME> -c_compile -finalize
ec -config <PROJECT_NAME>.ecf -target tests -c_compile -finalize
```

Final instruction for the LLM
- Produce the full file list and contents for a minimal, runnable Eiffel project following the rules above. Keep files concise and valid. Provide the command-line compile and test commands (using `ec`/`ec.exe`) as described in the final section of this prompt.

Included template (example files)
Below are the example files included inline. You can reference these in the standalone prompt or use them as concrete examples that the LLM can reproduce when asked.

`project_template/eiffel_template.ecf (system-style example)`
```xml
<?xml version="1.0" encoding="ISO-8859-1"?>
<system xmlns="http://www.eiffel.com/developers/xml/configuration-1-23-0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.eiffel.com/developers/xml/configuration-1-23-0 http://www.eiffel.com/developers/xml/configuration-1-23-0.xsd" name="<PROJECT_NAME>" uuid="{TO BE GENERATED}" library_target="<PROJECT_NAME>">
    <target name="<PROJECT_NAME>">
        <root all_classes="true"/>
        <file_rule>
            <exclude>/EIFGENs$</exclude>
            <exclude>/\..*$</exclude>
        </file_rule>
        <option warning="warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true" loop="true" supplier_precondition="true"/>
        </option>
        <setting name="console_application" value="true"/>
        <setting name="total_order_on_reals" value="false"/>
        <setting name="dead_code_removal" value="feature"/>
        <library name="base" location="$ISE_LIBRARY\library\base\base.ecf"/>
        <cluster name="src" location="./src" recursive="true"/>
    </target>

    <target name="tests" extends="<PROJECT_NAME>">
        <root class="APPLICATION" feature="make"/>
        <option warning="warning">
            <assertions precondition="true" postcondition="true" check="true" invariant="true" loop="true" supplier_precondition="true"/>
        </option>
        <setting name="console_application" value="true"/>
        <library name="testing" location="$ISE_LIBRARY\library\testing\testing.ecf"/>
        <cluster name="testing" location="./testing" recursive="true"/>
    </target>

</system>
```

Note: The example above shows a "system"-style ECF that uses `<target>` entries, `<cluster>` for source folders and `<library>` references to standard Eiffel libraries. When generating a project, the LLM should ensure the produced ECF (or system-style configuration) lists both `src` and `testing` clusters and includes any required `library` entries so `ec` can locate `base` and `testing`.

`project_template/src/application.e`
```eiffel
note
	description: "<PROJECT_NAME> — demo application with a small Design-by-Contract example."
class
    APPLICATION
create
    make
feature
    make
            -- Entry point
        do
            io.put_string ("Hello from project template!%N")
        end
end
```

`project_template/testing/application.e`
```eiffel
note
	description: "<PROJECT_NAME> — demo application with a small Design-by-Contract example."

class
    TEST_APPLICATION

feature
    run
        do
            io.put_string ("AutoTest: smoke test passed for project template.%N")
        end

end
```

The LLM may copy or adapt these example files when generating a new project; however, the standalone prompt above does not require the `templates/` folder to exist — these are provided purely for convenience and clarity.

Command-line compile & test (ec options)

This section lists generic `ec`/`ec.exe` command-line options and examples to compile and run a generated Eiffel project. These are intentionally not PowerShell-specific — they are plain command-line invocations that an LLM or CI job can use.

Typical options (common across EiffelStudio versions):
- `-config <file>`: specify the `.ecf` project file to use (e.g. `-config MyApp.ecf`).
- `-target <name>`: select the named build target from the ECF (if multiple targets exist).
- `-c_compile`: request C compilation of the generated C sources (useful when moving from compile to finalize).
- `-finalize`: perform finalization/build steps to produce the final executable under `EIFGENs/`.
- `-batch`: run in non-interactive/batch mode (when supported by the version).
- `-version`: print the `ec` version and exit (useful in CI to verify installed EiffelStudio).

Example invocations (replace placeholders):
- Minimal compile/finalize:

  ec -config <PROJECT_NAME>.ecf -c_compile -finalize

- Specify a target and run non-interactively:

  ec -config <PROJECT_NAME>.ecf -target default -c_compile -finalize -batch

- If `ec` is installed with a full path (Windows example):

  "C:/Program Files/Eiffel Software/EiffelStudio/<version>/bin/ec.exe" -config <PROJECT_NAME>.ecf -c_compile -finalize

Running the built executable / test runner
- After a successful build, the produced executable or test runner is typically under `EIFGENs/<target>/final/bin/` (Windows: `*.exe`; Unix: no extension).
- Run it by invoking the executable directly. Example (Unix-like): `./EIFGENs/default/final/bin/<exe>`; Windows: `EIFGENs\default\final\bin\<exe>.exe`.

Notes and CI tips
- Flags and exact option names can vary slightly by EiffelStudio version; use `ec -version` to confirm and consult your version's docs if an option is unrecognized.
- For CI, ensure the runner has EiffelStudio installed or use a self-hosted runner with `ec` available at a known path.
- If your ECF defines multiple build configurations (debug/release), pass the appropriate `-target` or config flags as defined in the ECF.

*** End of Prompt v1
