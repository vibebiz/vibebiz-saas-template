#!/bin/bash
#
# VibeBiz Security Scanner
# Implements comprehensive security scanning for Foundation+ stages
# Includes secret scanning, static analysis, dependency scanning, and container security
#

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Default scan type
SCAN_TYPE="${1:-all}"

# Available scan types
AVAILABLE_SCANS="secrets static deps containers iac all"

# Function to print colored output
print_header() {
    echo -e "${BLUE}🛡️  $1${NC}"
    echo "=================================================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run secret scanning
run_secret_scan() {
    print_header "Secret Scanning with Gitleaks"

    if command_exists gitleaks; then
        echo "→ Running Gitleaks secret scan..."
        gitleaks detect --source . -v --report-format json --report-path gitleaks-report.json || true
        print_success "Gitleaks scan completed - check gitleaks-report.json"
    else
        print_warning "Gitleaks not installed - install with: brew install gitleaks"
        return 1
    fi
}

# Function to run static analysis
run_static_analysis() {
    print_header "Static Security Analysis"

    # Python security with Bandit
    echo "→ Running Bandit (Python security)..."
    if command_exists bandit; then
        python -m bandit -r services/ packages/ \
            -f json -o bandit-report.json \
            -f txt -o bandit-results.txt || true
        print_success "Bandit scan completed"
    else
        print_warning "Bandit not installed - install with: pip install bandit"
    fi

    # Static analysis with Semgrep
    echo "→ Running Semgrep (multi-language static analysis)..."
    if command_exists semgrep; then
        semgrep --config=auto --json --output=semgrep-report.json . || true
        semgrep --config=auto --output=semgrep-results.txt . || true
        print_success "Semgrep scan completed"
    else
        print_warning "Semgrep not installed - install with: pip install semgrep"
    fi

    # JavaScript/TypeScript security
    echo "→ Running ESLint security checks..."
    if command_exists npx; then
        npx eslint --ext .ts,.tsx,.js,.jsx \
            --format json --output-file eslint-security-report.json \
            apps/ packages/ || true
        print_success "ESLint security scan completed"
    else
        print_warning "Node.js/npm not found"
    fi
}

# Function to run dependency scanning
run_dependency_scan() {
    print_header "Dependency Vulnerability Scanning"

    # Python dependencies with Safety
    echo "→ Running Safety (Python dependencies)..."
    if command_exists safety; then
        python -m safety check --json --output safety-report.json || true
        python -m safety check --output safety-results.txt || true
        print_success "Safety scan completed"
    else
        print_warning "Safety not installed - install with: pip install safety"
    fi

    # Node.js dependencies with npm audit
    echo "→ Running npm audit (Node.js dependencies)..."
    if command_exists npm; then
        npm audit --audit-level=moderate --json > npm-audit-report.json 2>/dev/null || true
        npm audit --audit-level=moderate > npm-audit-results.txt 2>/dev/null || true
        print_success "npm audit completed"
    else
        print_warning "npm not found"
    fi

    # Filesystem scan with Trivy
    echo "→ Running Trivy filesystem scan..."
    if command_exists trivy; then
        trivy fs --format json --output trivy-fs-report.json . || true
        trivy fs --format table --output trivy-fs-results.txt . || true
        print_success "Trivy filesystem scan completed"
    elif command_exists docker; then
        echo "  Using Trivy via Docker..."
        docker run --rm -v "$PWD:/workspace" aquasec/trivy fs \
            --format json --output /workspace/trivy-fs-report.json /workspace || true
        docker run --rm -v "$PWD:/workspace" aquasec/trivy fs \
            --format table --output /workspace/trivy-fs-results.txt /workspace || true
        print_success "Trivy filesystem scan completed"
    else
        print_warning "Trivy not installed - install with: brew install trivy"
    fi
}

# Function to run container security scanning
run_container_scan() {
    print_header "Container Security Scanning"

    # Dockerfile linting with Hadolint
    echo "→ Running Hadolint (Dockerfile security)..."
    find . -name "Dockerfile*" -type f | while read -r dockerfile; do
        echo "  Scanning $dockerfile..."
        if command_exists hadolint; then
            hadolint "$dockerfile" > "hadolint-$(basename "$dockerfile").txt" 2>&1 || true
        elif command_exists docker; then
            docker run --rm -i hadolint/hadolint < "$dockerfile" > "hadolint-$(basename "$dockerfile").txt" 2>&1 || true
        else
            print_warning "Hadolint not available - install with: brew install hadolint"
            return 1
        fi
    done

    # Container image scanning with Trivy
    echo "→ Scanning container images with Trivy..."
    if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -v "REPOSITORY" | while read -r image; do
        if [[ "$image" != "<none>:<none>" ]]; then
            echo "  Scanning image: $image"
            if command_exists trivy; then
                trivy image --format json --output "trivy-image-$(echo "$image" | tr '/:' '-').json" "$image" || true
            elif command_exists docker; then
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy image --format json \
                    --output "/tmp/trivy-image-$(echo "$image" | tr '/:' '-').json" "$image" || true
            fi
        fi
    done; then
        print_success "Container image scanning completed"
    else
        print_warning "No container images found to scan"
    fi
}

# Function to run Infrastructure as Code scanning
run_iac_scan() {
    print_header "Infrastructure as Code Security Scanning"

    # Check if we have Terraform files
    if find . -name "*.tf" -type f | head -1 | grep -q .; then
        echo "→ Running tfsec (Terraform security)..."
        if command_exists tfsec; then
            tfsec --format json --out tfsec-report.json . || true
            tfsec . > tfsec-results.txt 2>&1 || true
            print_success "tfsec scan completed"
        elif command_exists docker; then
            docker run --rm -v "$PWD:/src" aquasec/tfsec \
                --format json --out /src/tfsec-report.json /src || true
            docker run --rm -v "$PWD:/src" aquasec/tfsec /src > tfsec-results.txt 2>&1 || true
            print_success "tfsec scan completed"
        else
            print_warning "tfsec not installed - install with: brew install tfsec"
        fi

        echo "→ Running Checkov (IaC security)..."
        if command_exists checkov; then
            checkov -d . --framework terraform --output json --output-file checkov-report.json || true
            checkov -d . --framework terraform > checkov-results.txt 2>&1 || true
            print_success "Checkov scan completed"
        elif command_exists docker; then
            docker run --rm -v "$PWD:/tf" bridgecrew/checkov \
                -d /tf --framework terraform --output json --output-file /tf/checkov-report.json || true
            docker run --rm -v "$PWD:/tf" bridgecrew/checkov \
                -d /tf --framework terraform > checkov-results.txt 2>&1 || true
            print_success "Checkov scan completed"
        else
            print_warning "Checkov not installed - install with: pip install checkov"
        fi
    else
        print_warning "No Terraform files found, skipping IaC scans"
    fi

    # Scan Kubernetes files if they exist
    if find . -name "*.yaml" -o -name "*.yml" | xargs grep -l "kind:" | head -1 | grep -q .; then
        echo "→ Running Kubernetes security scans..."
        if command_exists checkov; then
            checkov -d . --framework kubernetes --output json --output-file checkov-k8s-report.json || true
            print_success "Kubernetes security scan completed"
        fi
    fi
}

# Function to generate security summary
generate_summary() {
    print_header "Security Scan Summary"

    cat > security-scan-summary.md << EOF
# 🛡️ VibeBiz Security Scan Summary

**Generated:** $(date)
**Scan Type:** $SCAN_TYPE
**Project:** VibeBiz SaaS Template

## 📊 Scan Results Overview

### Secret Scanning
- **Gitleaks**: $([ -f gitleaks-report.json ] && echo "✅ Completed" || echo "❌ Not run")

### Static Security Analysis
- **Bandit (Python)**: $([ -f bandit-report.json ] && echo "✅ Completed" || echo "❌ Not run")
- **Semgrep (Multi-language)**: $([ -f semgrep-report.json ] && echo "✅ Completed" || echo "❌ Not run")
- **ESLint Security**: $([ -f eslint-security-report.json ] && echo "✅ Completed" || echo "❌ Not run")

### Dependency Scanning
- **Safety (Python)**: $([ -f safety-report.json ] && echo "✅ Completed" || echo "❌ Not run")
- **npm audit (Node.js)**: $([ -f npm-audit-report.json ] && echo "✅ Completed" || echo "❌ Not run")
- **Trivy (Filesystem)**: $([ -f trivy-fs-report.json ] && echo "✅ Completed" || echo "❌ Not run")

### Container Security
- **Hadolint (Dockerfile)**: $(ls hadolint-*.txt 2>/dev/null | wc -l | awk '{if($1>0) print "✅ Completed"; else print "❌ Not run"}')
- **Trivy (Images)**: $(ls trivy-image-*.json 2>/dev/null | wc -l | awk '{if($1>0) print "✅ Completed"; else print "❌ Not run"}')

### Infrastructure as Code
- **tfsec (Terraform)**: $([ -f tfsec-report.json ] && echo "✅ Completed" || echo "❌ Not run")
- **Checkov (IaC)**: $([ -f checkov-report.json ] && echo "✅ Completed" || echo "❌ Not run")

## 📋 Report Files Generated

$(find . -maxdepth 1 -name "*-report.json" -o -name "*-results.txt" | sort | sed 's/^/- /')

## 🚨 Critical Actions Required

**Review HIGH and CRITICAL findings in:**
1. Secrets detected by Gitleaks
2. Security vulnerabilities in dependencies
3. Container security issues
4. Infrastructure misconfigurations

## 📈 Recommended Next Steps

1. **Immediate**: Address any secrets found by Gitleaks
2. **High Priority**: Fix HIGH/CRITICAL vulnerabilities in dependencies
3. **Medium Priority**: Review and fix static analysis findings
4. **Low Priority**: Address informational findings and improve security posture

## 🔧 Quick Fix Commands

\`\`\`bash
# Update Python dependencies
pip-audit --fix

# Update Node.js dependencies
npm audit fix

# Re-run security scans
./scripts/security-scan.sh all
\`\`\`

---
*Generated by VibeBiz Security Scanner v1.0*
EOF

    print_success "Security summary generated: security-scan-summary.md"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [scan_type]"
    echo ""
    echo "Available scan types:"
    echo "  secrets    - Secret scanning with Gitleaks"
    echo "  static     - Static security analysis (Bandit, Semgrep, ESLint)"
    echo "  deps       - Dependency vulnerability scanning"
    echo "  containers - Container and Dockerfile security"
    echo "  iac        - Infrastructure as Code security"
    echo "  all        - Run all security scans (default)"
    echo ""
    echo "Examples:"
    echo "  $0                 # Run all scans"
    echo "  $0 secrets         # Run only secret scanning"
    echo "  $0 static          # Run only static analysis"
}

# Main execution
main() {
    case "$SCAN_TYPE" in
        "secrets")
            run_secret_scan
            ;;
        "static")
            run_static_analysis
            ;;
        "deps")
            run_dependency_scan
            ;;
        "containers")
            run_container_scan
            ;;
        "iac")
            run_iac_scan
            ;;
        "all")
            print_header "VibeBiz Foundation+ Security Scanner"
            echo "Running comprehensive security scans..."
            echo ""

            run_secret_scan
            echo ""
            run_static_analysis
            echo ""
            run_dependency_scan
            echo ""
            run_container_scan
            echo ""
            run_iac_scan
            echo ""
            generate_summary
            ;;
        "help"|"-h"|"--help")
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown scan type: $SCAN_TYPE"
            echo ""
            show_usage
            exit 1
            ;;
    esac

    echo ""
    print_success "Security scan ($SCAN_TYPE) completed!"
    echo ""
    echo "📂 Check generated report files for detailed results:"
    ls -la *-report.json *-results.txt security-scan-summary.md 2>/dev/null || echo "  No report files found"
}

# Check for help flag
if [[ "$1" == "help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Run main function
main
