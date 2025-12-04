aws cognito-idp set-ui-customization \
  --user-pool-id 	us-east-1_CKbYONuNe \
  --client-id ALL \
  --css file://$(pwd)/cognito_custom_ui.css \
  --image-file fileb://$(pwd)/CharlesBrady_logo.png
