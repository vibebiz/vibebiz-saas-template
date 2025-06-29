# How to Set Up Spectral

It appears you're encountering the error:

```text
🙅‍ error: You need to provide your key (Spectral DSN).
To get your DSN: 🌍 visit: https://get.spectralops.io/signup
```

This indicates that the Spectral CLI requires a valid DSN (Data Source Name)
to function. Here's how you can set it up:

---

## 🔐 Step 1: Obtain Your Spectral DSN

1. **Sign Up or Log In**: Visit
   [https://get.spectralops.io/signup](https://get.spectralops.io/signup) to create
   an account or log in.
2. **Retrieve DSN**: After logging in, navigate to **Settings → Organization**
   to find your DSN key.

---

## ⚙️ Step 2: Configure the DSN

You can provide the DSN to Spectral in several ways:

### Option 1: Set as an Environment Variable (Recommended)

For Unix-based systems (Linux/macOS):

```bash
export SPECTRAL_DSN=<your-dsn>
```

For Windows PowerShell:

```powershell
$env:SPECTRAL_DSN = "<your-dsn>"
```

Replace `<your-dsn>` with your actual DSN key.

#### Option 2: Use the `login` Command

Spectral offers a login command to store your DSN:

```bash
spectral login --dsn <your-dsn>
```

This securely saves your DSN for future use.

---

## 🧪 Step 3: Run a Test Scan

To verify that Spectral is set up correctly:

```bash
spectral scan
```

If everything is configured properly, you should see output indicating the scan
results.

---

## 🛠️ Additional Tips

- **CI/CD Integration**: When integrating Spectral into CI/CD pipelines (e.g.,
  GitHub Actions, GitLab CI), store the `SPECTRAL_DSN` as a secret or
  environment variable within your pipeline configuration.
- **Inspect Installation Scripts**: As a security best practice, always review
  installation scripts before executing them. Spectral provides installation
  scripts that you can inspect prior to running.

If you encounter further issues or need assistance with specific integrations,
feel free to ask!
