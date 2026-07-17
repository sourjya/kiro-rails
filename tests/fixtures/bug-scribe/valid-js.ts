// Some existing code

export async function fetchUsers() {
  // BUG: RACE_CONDITION — async timing causes stale data render
  const data = await api.get('/users');
  return data;
}
