aws cognito-idp set-ui-customization \
  --user-pool-id us-east-1_YIYfB6zj2 \
  --client-id ALL \
  --css file://$(pwd)/cognito_custom_ui.css \
  --image-file fileb://$(pwd)/charles_portrait.png
