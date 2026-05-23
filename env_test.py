import os
import json
import base64

payload = os.environ["OIDC_TOKEN"].split(".")[1]
payload += "=" * (-len(payload) % 4)
claims = json.loads(base64.urlsafe_b64decode(payload).decode())
print(f"aud: {claims.get('aud')}")
print(f"sub: {claims.get('sub')}")