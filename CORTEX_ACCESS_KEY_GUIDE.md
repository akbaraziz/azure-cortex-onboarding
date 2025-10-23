# How to Create Cortex Cloud Access Keys

## 🔑 Step-by-Step Guide

### Step 1: Login to Cortex Cloud Portal

1. Navigate to: **https://app.prismacloud.io** (or your region's URL)
2. Sign in with your credentials

### Step 2: Navigate to Access Keys

1. Click on **Settings** (⚙️ icon) in the left sidebar
2. Click on **Access Keys**
3. Click **+ Add** or **+ Add New** button

### Step 3: Create Access Key

1. **Name**: Enter a descriptive name (e.g., "Azure-Terraform-Integration")
2. **Expiration**: Choose expiration period (recommend 1 year)
3. Click **Create**

### Step 4: Save Your Credentials ⚠️ IMPORTANT!

You'll see a popup with:
- **Access Key ID**: (starts with something like: `12345678-abcd-1234-...`)
- **Secret Key**: (long random string)

**⚠️  CRITICAL:** The Secret Key is shown **ONLY ONCE!**
- Copy both values immediately
- Store them securely (password manager recommended)
- You cannot retrieve the Secret Key later

### Step 5: Update terraform.tfvars

Once you have your keys, update these lines in `terraform.tfvars`:

```hcl
# Replace with your actual Access Key ID
cortex_access_key = "YOUR-ACCESS-KEY-ID-HERE"

# Replace with your actual Secret Key (shown only once!)
cortex_secret_key = "YOUR-SECRET-KEY-HERE"
```

### Step 6: Verify Access

Test your keys work (optional but recommended):

```bash
# Using curl to test authentication
curl -X POST https://api.prismacloud.io/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "YOUR-ACCESS-KEY-ID",
    "password": "YOUR-SECRET-KEY"
  }'

# Should return a JWT token if successful
```

---

## 🔒 Security Best Practices

1. **Never commit terraform.tfvars** to version control
   ```bash
   # Verify it's in .gitignore
   grep terraform.tfvars .gitignore

   # If not, add it:
   echo "terraform.tfvars" >> .gitignore
   ```

2. **Rotate keys regularly** (every 90-365 days)

3. **Use separate keys** for different environments (dev/test/prod)

4. **Revoke old keys** when no longer needed

5. **Store securely** - Use a password manager or secrets vault

---

## ❓ Troubleshooting

### Issue: Can't find Access Keys menu

**Solution:** You may not have the required permissions. You need:
- **System Admin** role, OR
- **Account Group Admin** role with "Manage Access Keys" permission

Contact your Cortex Cloud administrator.

### Issue: Lost my Secret Key

**Solution:** You cannot retrieve it. You must:
1. Delete the old access key
2. Create a new access key
3. Update terraform.tfvars with the new credentials

### Issue: Authentication fails

**Possible causes:**
1. Wrong API region (check cortex_api_url)
2. Typo in Access Key or Secret Key
3. Access key expired or revoked
4. Access key doesn't have required permissions

---

## ✅ Next Steps

Once you've created and saved your Access Keys:

1. ✅ Update `terraform.tfvars` with your credentials
2. ✅ Verify the file has no syntax errors:
   ```bash
   cat terraform.tfvars | grep -E "(cortex_access_key|cortex_secret_key)"
   ```
3. ✅ Run terraform plan:
   ```bash
   terraform plan -out=migration.tfplan
   ```

---

## 📚 Additional Resources

- [Cortex Cloud Access Keys Documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin/manage-prisma-cloud-administrators/create-access-keys)
- [API Authentication Guide](https://pan.dev/prisma-cloud/api/cspm/api-integration-config/)

---

**Ready to proceed?**

After creating your keys and updating terraform.tfvars, let me know and I'll help you run terraform plan!
