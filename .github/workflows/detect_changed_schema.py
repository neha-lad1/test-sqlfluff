import subprocess
import os

def get_changed_schemas(base_dir="SQL"):
    base = os.environ.get("GITHUB_BASE_REF")
    head = os.environ.get("GITHUB_HEAD_REF")

    if not base or not head:
        print("::warning::GITHUB_BASE_REF or GITHUB_HEAD_REF not set. Is this a PR?")
        return []

    try:
        subprocess.run(["git", "fetch", "origin", base], check=True)

        result = subprocess.run(
            ["git", "diff", "--name-only", f"origin/{base}...{head}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )

        changed_files = result.stdout.strip().split('\n')
        changed_schemas = set()

        for file_path in changed_files:
            if file_path.startswith(base_dir + "/"):
                parts = file_path.split('/')
                if len(parts) >= 2:
                    changed_schemas.add(parts[1])

        return list(changed_schemas)

    except subprocess.CalledProcessError as e:
        print(f"::error::Git error: {e.stderr}")
        return []

if __name__ == "__main__":
    schemas = get_changed_schemas()
    output = ",".join(schemas)
    
    # Use the new way to set output in GitHub Actions
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a") as fh:
            print(f"changed_schemas={output}", file=fh)
