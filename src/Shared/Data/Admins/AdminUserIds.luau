-- PRIVATE STATE
const _admins = {
	[2600715546] = true,
}

-- PUBLIC MODULE
const AdminUserIds = {}

function AdminUserIds.IsAdmin(userId: number)
	return _admins[userId]
end

return AdminUserIds
