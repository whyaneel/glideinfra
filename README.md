name: Check EKS Cluster Status

on:
workflow_dispatch:
schedule:
# Run every day at midnight UTC
- cron: '0 0 * * *'

jobs:
check-status:
runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Get Cluster Details
        id: cluster-details
        run: |
          if [[ -f "cluster-status/status.txt" && -f "cluster-status/name.txt" && -f "cluster-status/region.txt" ]]; then
            STATUS=$(cat cluster-status/status.txt)
            CLUSTER_NAME=$(cat cluster-status/name.txt)
            REGION=$(cat cluster-status/region.txt)
            
            echo "status=${STATUS}" >> $GITHUB_OUTPUT
            echo "cluster_name=${CLUSTER_NAME}" >> $GITHUB_OUTPUT
            echo "region=${REGION}" >> $GITHUB_OUTPUT
            
            if [[ -f "cluster-status/timestamp.txt" ]]; then
              TIMESTAMP=$(cat cluster-status/timestamp.txt)
              CURRENT_TIME=$(date +%s)
              DIFF=$((CURRENT_TIME - TIMESTAMP))
              DAYS=$((DIFF / 86400))
              echo "age_days=${DAYS}" >> $GITHUB_OUTPUT
            else
              echo "age_days=unknown" >> $GITHUB_OUTPUT
            fi
          else
            echo "status=UNKNOWN" >> $GITHUB_OUTPUT
            echo "cluster_name=unknown" >> $GITHUB_OUTPUT
            echo "region=unknown" >> $GITHUB_OUTPUT
            echo "age_days=unknown" >> $GITHUB_OUTPUT
          fi

      - name: Configure AWS credentials
        if: steps.cluster-details.outputs.status == 'ACTIVE'
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ steps.cluster-details.outputs.region }}

      - name: Verify Cluster Existence
        if: steps.cluster-details.outputs.status == 'ACTIVE'
        id: verify-cluster
        continue-on-error: true
        run: |
          if aws eks describe-cluster --name "${{ steps.cluster-details.outputs.cluster_name }}" --region "${{ steps.cluster-details.outputs.region }}"; then
            echo "cluster_exists=true" >> $GITHUB_OUTPUT
          else
            echo "cluster_exists=false" >> $GITHUB_OUTPUT
          fi

      - name: Send Notification for Long-Running Clusters
        if: steps.cluster-details.outputs.status == 'ACTIVE' && steps.verify-cluster.outputs.cluster_exists == 'true' && steps.cluster-details.outputs.age_days != 'unknown' && steps.cluster-details.outputs.age_days > 2
        run: |
          echo "::warning::EKS cluster '${{ steps.cluster-details.outputs.cluster_name }}' has been running for ${{ steps.cluster-details.outputs.age_days }} days. Consider destroying it if not in use to save costs."
          
          # Create issue if cluster is older than 3 days
          if [[ ${{ steps.cluster-details.outputs.age_days }} -gt 3 ]]; then
            # Using GitHub CLI if available
            if command -v gh &> /dev/null; then
              gh auth login --with-token <<< "${{ secrets.GITHUB_TOKEN }}"
              ISSUE_EXISTS=$(gh issue list --search "Long-running EKS cluster ${{ steps.cluster-details.outputs.cluster_name }}" --json number | jq '.[].number')
              
              if [[ -z "$ISSUE_EXISTS" ]]; then
                gh issue create --title "Long-running EKS cluster: ${{ steps.cluster-details.outputs.cluster_name }}" \
                  --body "EKS cluster '${{ steps.cluster-details.outputs.cluster_name }}' has been running for ${{ steps.cluster-details.outputs.age_days }} days in region '${{ steps.cluster-details.outputs.region }}'.\n\nConsider destroying it if not in use to save costs.\n\nYou can destroy it by:\n1. Using the GitHub Actions workflow 'Destroy EKS Cluster'\n2. Adding [destroy-eks] to a commit message\n3. Running 'make destroy' locally" \
                  --label "cost-alert"
              fi
            fi
          fi

      - name: Update Status if Cluster Not Found
        if: steps.cluster-details.outputs.status == 'ACTIVE' && steps.verify-cluster.outputs.cluster_exists == 'false'
        run: |
          echo "Cluster marked as ACTIVE but doesn't exist. Updating status..."
          mkdir -p cluster-status
          echo "DESTROYED" > cluster-status/status.txt
          echo "${{ steps.cluster-details.outputs.cluster_name }}" > cluster-status/name.txt
          echo "${{ steps.cluster-details.outputs.region }}" > cluster-status/region.txt
          echo "$(date +%s)" > cluster-status/timestamp.txt
          
          git config --global user.name 'GitHub Actions'
          git config --global user.email 'actions@github.com'
          git add cluster-status/
          git commit -m "Update cluster status to DESTROYED (auto-detected) [skip ci]" || echo "No changes to commit"
          git push