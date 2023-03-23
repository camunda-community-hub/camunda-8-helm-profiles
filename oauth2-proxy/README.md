1. Create a new client for oauth2-proxy

Use the following command to determine keycloak password

```shell
make keykloak-password
```

Sign in and Click `clients`, then `Create`. Set Client ID to `oauth2` and accept default of `openid-connect`. 

Add the following to `Valid Redirect URIs`

```shell
https://gke.upgradingdave.com/oauth2/callback
```

Copy and paste the client secret generated for this client and add it to the your Makefile

Configure a new Audience Mapper. 

- Use `oauth2 Audience Mapper` for the name
- Select `Audience` for Mapper Type
- Choose your `oauth2` client for the included Client Audience

2. Create a zeebe client

- Create a zeebe client in the normal way
- Create a client scope in keycloak. Set name to `oauth2`. Set protocol `openid-connect`. 
- Click on mappers tab and create new mapper. Name can be anything. Set `Included Client Audience` to `oauth2` (the client you created in step 1 above)
- Save

# Connecting from Desktop Modeler

zbctl status --address gke.upgradingdave.com:443 --clientId zeebe --clientSecret xxx --authzUrl https://gke.upgradingdave.com/auth/realms/camunda-platform/protocol/openid-connect/token

https://gke.upgradingdave.com/auth/realms/camunda-platform/protocol/openid-connect/token
