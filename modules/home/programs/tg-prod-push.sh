# tg-prod-push - Push Docker images from Development ECR to Production ECR
#
# Usage: tg-prod-push [--dry-run] <ECR_IMAGE>
#
# This script:
#   1. Authenticates to Development AWS ECR (profile: default)
#   2. Authenticates to Production AWS ECR (profile: tg-prod-0)
#   3. Pulls the image from dev, tags it for prod, and pushes to prod
#
# Prerequisites:
#   - AWS CLI configured with profiles: default, tg-prod-0
#   - Docker installed and running

# errexit / nounset / pipefail are set by writeShellApplication.

# ==============================================================================
# Configuration
# ==============================================================================

SCRIPT_NAME="${0##*/}"
readonly SCRIPT_NAME
readonly SCRIPT_VERSION="1.1.0"

# Runtime flags
DRY_RUN=false

# Initialize AWS_PROFILE if not set (some shells with nounset trip otherwise).
export AWS_PROFILE="${AWS_PROFILE:-}"

# AWS Configuration
readonly DEV_AWS_PROFILE="default"
readonly PROD_AWS_PROFILE="tg-prod-0"
readonly AWS_REGION="eu-central-1"

# ECR Configuration
readonly DEV_ECR_REGISTRY="713614461671.dkr.ecr.${AWS_REGION}.amazonaws.com"
readonly PROD_ECR_REGISTRY="530145339946.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Colors for output (disabled if not a terminal)
if [[ -t 1 ]]; then
    readonly RED=$'\033[0;31m'
    readonly GREEN=$'\033[0;32m'
    readonly YELLOW=$'\033[0;33m'
    readonly BLUE=$'\033[0;34m'
    readonly CYAN=$'\033[0;36m'
    readonly BOLD=$'\033[1m'
    readonly NC=$'\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly CYAN=''
    readonly BOLD=''
    readonly NC=''
fi

# ==============================================================================
# Logging Functions
# ==============================================================================

log_info()    { printf '%b[INFO]%b %s\n'    "${BLUE}"   "${NC}" "$*"; }
log_success() { printf '%b[SUCCESS]%b %s\n' "${GREEN}"  "${NC}" "$*"; }
log_warn()    { printf '%b[WARN]%b %s\n'    "${YELLOW}" "${NC}" "$*" >&2; }
log_error()   { printf '%b[ERROR]%b %s\n'   "${RED}"    "${NC}" "$*" >&2; }
log_step()    { printf '\n%b%b==>%b %b%s%b\n' "${BOLD}" "${CYAN}" "${NC}" "${BOLD}" "$*" "${NC}"; }
log_dry()     { printf '%b[DRY-RUN]%b Would execute: %b%s%b\n' "${YELLOW}" "${NC}" "${BOLD}" "$*" "${NC}"; }

# ==============================================================================
# Helper Functions
# ==============================================================================

usage() {
    cat << EOF
${BOLD}${SCRIPT_NAME}${NC} v${SCRIPT_VERSION} - Push Docker images from Dev ECR to Prod ECR
${BOLD}USAGE:${NC}
    ${SCRIPT_NAME} [OPTIONS] <ECR_IMAGE>
${BOLD}ARGUMENTS:${NC}
    ECR_IMAGE    The image name with tag (e.g., myapp:v1.2.3 or myapp/service:latest)
${BOLD}OPTIONS:${NC}
    --dry-run    Authenticate to ECRs but only print docker commands without executing
    -h, --help   Show this help message
    -v, --version Show version
${BOLD}EXAMPLES:${NC}
    ${SCRIPT_NAME} myapp:v1.2.3
    ${SCRIPT_NAME} --dry-run myapp:v1.2.3
    ${SCRIPT_NAME} services/api:latest
    ${SCRIPT_NAME} backend/worker:abc123
${BOLD}ENVIRONMENT:${NC}
    Development Registry: ${DEV_ECR_REGISTRY}
    Production Registry:  ${PROD_ECR_REGISTRY}
    AWS Region:           ${AWS_REGION}
${BOLD}PREREQUISITES:${NC}
    - AWS CLI with profiles: ${DEV_AWS_PROFILE}, ${PROD_AWS_PROFILE}
    - Docker running
EOF
}

cleanup() {
    local exit_code=$?

    # Restore to default profile on exit (best effort)
    export AWS_PROFILE="${DEV_AWS_PROFILE}"

    if [[ ${exit_code} -ne 0 ]]; then
        echo ""
        log_error "Script failed with exit code ${exit_code}"
    fi

    exit "${exit_code}"
}

check_prerequisites() {
    # aws-cli and docker are pinned in runtimeInputs, so they're always on
    # PATH. The only thing worth checking at runtime is the daemon.
    if ! timeout 10 docker info &>/dev/null; then
        log_error "Docker daemon is not running or not responding. Please start Docker and try again."
        exit 1
    fi
}

validate_input() {
    local ecr_image="$1"

    if [[ -z "${ecr_image}" ]]; then
        log_error "ECR_IMAGE cannot be empty"
        usage
        exit 1
    fi

    if [[ ! "${ecr_image}" =~ ^[a-zA-Z0-9][a-zA-Z0-9._/-]*:[a-zA-Z0-9._-]+$ ]] && \
       [[ ! "${ecr_image}" =~ ^[a-zA-Z0-9][a-zA-Z0-9._/-]*$ ]]; then
        log_warn "Image format looks unusual: ${ecr_image}"
        log_warn "Expected format: name:tag or repository/name:tag"
        read -r -p "Continue anyway? [y/N] " response
        if [[ ! "${response}" =~ ^[Yy]$ ]]; then
            log_info "Aborted by user"
            exit 0
        fi
    fi
}

switch_aws_profile() {
    local profile="$1"
    local description="$2"

    log_info "Switching to AWS profile: ${profile} (${description})"

    export AWS_PROFILE="${profile}"

    if ! aws configure list-profiles 2>/dev/null | grep -q "^${profile}$"; then
        log_error "AWS profile '${profile}' not found"
        log_error "Available profiles: $(aws configure list-profiles 2>/dev/null | tr '\n' ' ')"
        exit 1
    fi

    log_success "Using AWS profile: ${profile}"
}

ecr_login() {
    local registry="$1"
    local description="$2"

    log_info "Authenticating to ECR: ${description}"

    local login_output
    if ! login_output=$(aws ecr get-login-password --region "${AWS_REGION}" 2>&1 | \
                        docker login --username AWS --password-stdin "${registry}" 2>&1); then
        log_error "ECR login failed for ${description}"
        log_error "Output: ${login_output}"
        exit 1
    fi

    log_success "ECR login successful: ${description}"
}

# ==============================================================================
# Main Operations
# ==============================================================================

pull_image() {
    local image="$1"
    local full_image="${DEV_ECR_REGISTRY}/${image}"

    log_step "Pulling image from Development ECR"
    log_info "Image: ${full_image}"
    echo ""

    if ! docker pull "${full_image}"; then
        log_error "Failed to pull image: ${full_image}"
        exit 1
    fi

    log_success "Image pulled successfully"
}

tag_image() {
    local image="$1"
    local source="${DEV_ECR_REGISTRY}/${image}"
    local target="${PROD_ECR_REGISTRY}/${image}"

    log_step "Tagging image for Production ECR"
    log_info "Source: ${source}"
    log_info "Target: ${target}"

    if ! docker tag "${source}" "${target}"; then
        log_error "Failed to tag image"
        exit 1
    fi

    log_success "Image tagged successfully"
}

push_image() {
    local image="$1"
    local full_image="${PROD_ECR_REGISTRY}/${image}"

    log_step "Pushing image to Production ECR"
    log_info "Image: ${full_image}"
    echo ""

    if ! docker push "${full_image}"; then
        log_error "Failed to push image: ${full_image}"
        exit 1
    fi

    log_success "Image pushed successfully"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local ecr_image=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--version)
                echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -n "${ecr_image}" ]]; then
                    log_error "Unexpected argument: $1 (ECR_IMAGE already set to '${ecr_image}')"
                    usage
                    exit 1
                fi
                ecr_image="$1"
                shift
                ;;
        esac
    done

    if [[ -z "${ecr_image}" ]]; then
        log_error "ECR_IMAGE is required"
        usage
        exit 1
    fi

    trap cleanup EXIT INT TERM

    echo ""
    printf '%b========================================%b\n' "${BOLD}" "${NC}"
    if [[ "${DRY_RUN}" == true ]]; then
        printf '%b  ECR Image Push: Dev -> Production%b\n' "${BOLD}" "${NC}"
        printf '%b%b            [DRY-RUN MODE]%b\n' "${YELLOW}" "${BOLD}" "${NC}"
    else
        printf '%b  ECR Image Push: Dev -> Production%b\n' "${BOLD}" "${NC}"
    fi
    printf '%b========================================%b\n' "${BOLD}" "${NC}"
    echo ""
    log_info "Image: ${ecr_image}"
    log_info "Source: ${DEV_ECR_REGISTRY}"
    log_info "Target: ${PROD_ECR_REGISTRY}"
    if [[ "${DRY_RUN}" == true ]]; then
        log_warn "Dry-run mode: Docker commands will be printed but not executed"
    fi

    log_step "Checking prerequisites"
    check_prerequisites
    validate_input "${ecr_image}"
    log_success "All prerequisites satisfied"

    log_step "Step 1/5: Authenticate to Development ECR"
    switch_aws_profile "${DEV_AWS_PROFILE}" "Development"
    ecr_login "${DEV_ECR_REGISTRY}" "Development ECR"

    log_step "Step 2/5: Authenticate to Production ECR"
    switch_aws_profile "${PROD_AWS_PROFILE}" "Production"
    ecr_login "${PROD_ECR_REGISTRY}" "Production ECR"

    if [[ "${DRY_RUN}" == true ]]; then
        log_step "Step 3/5: Pull image from Development ECR (DRY-RUN)"
        log_dry "docker pull ${DEV_ECR_REGISTRY}/${ecr_image}"

        log_step "Step 4/5: Tag image for Production ECR (DRY-RUN)"
        log_dry "docker tag ${DEV_ECR_REGISTRY}/${ecr_image} ${PROD_ECR_REGISTRY}/${ecr_image}"

        log_step "Step 5/5: Push image to Production ECR (DRY-RUN)"
        log_dry "docker push ${PROD_ECR_REGISTRY}/${ecr_image}"

        echo ""
        printf '%b========================================%b\n' "${BOLD}" "${NC}"
        printf '%b%b  DRY-RUN COMPLETE%b\n' "${YELLOW}" "${BOLD}" "${NC}"
        printf '%b========================================%b\n' "${BOLD}" "${NC}"
        echo ""
        log_info "ECR authentication: verified"
        log_info "Image: ${ecr_image}"
        log_info "Commands above would transfer image to production"
        echo ""
    else
        pull_image "${ecr_image}"
        tag_image "${ecr_image}"
        push_image "${ecr_image}"

        echo ""
        printf '%b========================================%b\n' "${BOLD}" "${NC}"
        printf '%b%b  SUCCESS: Image pushed to production%b\n' "${GREEN}" "${BOLD}" "${NC}"
        printf '%b========================================%b\n' "${BOLD}" "${NC}"
        echo ""
        log_info "Image: ${ecr_image}"
        log_info "Production URL: ${PROD_ECR_REGISTRY}/${ecr_image}"
        echo ""
    fi
}

main "$@"
