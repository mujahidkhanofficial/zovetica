const int fixedAppointmentFeePkr = 1000;
const double platformCommissionRate = 0.15;

int calculatePlatformCommission(int totalFeePkr) {
  return (totalFeePkr * platformCommissionRate).round();
}

int calculateVetEarnings(int totalFeePkr) {
  return totalFeePkr - calculatePlatformCommission(totalFeePkr);
}
