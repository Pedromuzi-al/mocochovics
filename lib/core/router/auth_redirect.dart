String? authRedirect({
  required bool isAuthenticated,
  required bool isRecoveringPassword,
  required String path,
}) {
  const publicPaths = {'/login', '/register', '/forgot-password'};
  if (!isAuthenticated) return publicPaths.contains(path) ? null : '/login';
  if (isRecoveringPassword) {
    return path == '/reset-password' ? null : '/reset-password';
  }
  if (publicPaths.contains(path) || path == '/' || path == '/reset-password') {
    return '/inicio';
  }
  return null;
}
