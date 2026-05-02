--[=[
	Queue.luau
	A implementation of the circular queue data structure
]=]
-- SERVICES

-- IMPORTED MODULES

-- CONSTANTS
local DEFAULT_QUEUE_SIZE = 100

-- TYPES
type QueueImpl<T> = {
	__index: QueueImpl<T>,
	new: () -> Queue<T>,
	enqueue: (self: Queue<T>, value: T) -> (),
	dequeue: (self: Queue<T>) -> T?,
	peek: (self: Queue<T>) -> T?,
	isEmpty: (self: Queue<T>) -> boolean,
	isFull: (self: Queue<T>) -> boolean,
}

type QueueProto<T> = {
	_first: number,
	_size: number,
	_capacity: number,
	_data: { T },
}

export type Queue<T> = setmetatable<QueueProto<T>, QueueImpl<T>>

-- PRIVATE STATE

-- PRIVATE FUNCTIONS

-- PUBLIC MODULE
local Queue = {} :: QueueImpl<any>
Queue.__index = Queue

function Queue.new<T>(cap: number?): Queue<T>
	return setmetatable({
		_first = 1,
		_size = 0,
		_data = {} :: { T },
		_capacity = cap or DEFAULT_QUEUE_SIZE,
	}, Queue)
end

function Queue.enqueue<T>(self: Queue<T>, value: T)
	if self._size == self._capacity then
		-- warn("Queue is full. Consider expanding the capacity with :expand(amount)")
		warn("Queue is full.")
		return
	end
	-- 1 based index fix
	local rear = ((self._first - 1 + self._size) % self._capacity) + 1
	self._data[rear] = value
	self._size += 1
end

function Queue.dequeue<T>(self: Queue<T>): T?
	if self._size == 0 then
		return nil
	end

	local result = self._data[self._first]
	self._data[self._first] = nil
	-- 1 based index fix
	self._first = (self._first % self._capacity) + 1
	self._size -= 1
	return result
end

function Queue.peek<T>(self: Queue<T>): T?
	if self._size == 0 then
		return nil
	end

	local result = self._data[self._first]
	return result
end

function Queue.isEmpty<T>(self: Queue<T>): boolean
	return self._size == 0
end

function Queue.isFull<T>(self: Queue<T>): boolean
	return self._size == self._capacity
end

return Queue
