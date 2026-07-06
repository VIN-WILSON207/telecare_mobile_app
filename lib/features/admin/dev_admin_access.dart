const devAdminEmail = 'abilavinwilson@gmail.com';

bool isDevAdminEmail(String? email) {
  return email?.trim().toLowerCase() == devAdminEmail;
}
