extends Node

## A internal class to describe a task
class Task:
	extends RefCounted

	## The task id
	var id: int

	## The function to run
	var run_function: Callable

	## The function to callback
	var callback_function: Callable

	## Constructor
	func _init(id: int, run_function: Callable, callback_function: Callable) -> void:
		self.id = id
		self.run_function = run_function
		self.callback_function = callback_function

	## Internal function to run the task
	func run() -> void:
		# Get the result
		var res = run_function.call()

		# Has a callback function, call it (deferred, to avoid threading problems)
		if callback_function:
			callback_function.call_deferred(res)

## The pool of threads
var pool: Array[Thread]

## The dictionary of tasks
var tasks: Dictionary

## Queue of task ids
var queued_tasks: Array[int]

## Current task id
var task_id: int

## Semaphore used to execute one task
var task_wait: Semaphore

## Mutex used to read/write the tasks array
var task_lock: Mutex

## Flag used to stop all the threads
var finished: bool

## Called when initialized
func _init() -> void:
	task_wait = Semaphore.new()
	task_lock = Mutex.new()
	task_id = 1

## Called when receiving a notification
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			__initialize_pool()
		NOTIFICATION_EXIT_TREE:
			__finalize_pool()

## Queues a single task, provided the function to be run and a callback function (optional)
func queue_task(run_function: Callable, callback_function: Callable = Callable()) -> int:
	# Lock the task array
	task_lock.lock()

	# Get the task id
	var id: int = task_id

	# Add the new task
	tasks[id] = Task.new(id, run_function, callback_function)
	queued_tasks.push_front(id)
	task_id += 1

	# Unlock the task array
	task_lock.unlock()

	# Run the new task
	task_wait.post()

	# Return the task id
	return id

## Internal function to initialize the thread pool
func __initialize_pool() -> void:
	# Set finished to false
	finished = false

	# Get number of threads
	var count: int = ProjectSettings.get_setting("threading/thread_pool/max_threads", 0)

	# Automatic thread count
	if count == 0:
		count = OS.get_processor_count()
	
	count = 4

	# Create the pool
	pool.resize(count)
	for i in count:
		# Create the thread
		var t: Thread = Thread.new()
		pool[i] = t

		# Start the thread
		t.start(__thread_execute.bind(i))

## Internal function to finalize the thread pool
func __finalize_pool() -> void:
	# Set finished to true
	finished = true

	# Execute each task
	for th in pool:
		task_wait.post()
	
	# Clear the tasks
	task_lock.lock()
	tasks.clear()
	task_lock.unlock()
	
## Internal function to dequeue a single task
func __dequeue_task() -> Task:
	# Make sure that the task array is not empty
	assert(not tasks.is_empty(), "The task array is empty")
	
	# Lock the task array
	task_lock.lock()

	# Pop the first task id in the array
	var task_id: int = queued_tasks.pop_back()

	# Get the task
	var task: Task = tasks[task_id]
	tasks.erase(task_id)

	# Unlock the task array
	task_lock.unlock()

	# Return the fetched task
	return task

## Internal function executed by each thread
func __thread_execute(thread_id: int) -> void:
	while not finished:
		# Wait for a new task request
		task_wait.wait()

		# Is finished, cancel
		if finished: break

		# Fetch a single task
		var task: Task = __dequeue_task()

		# There is no task, continue
		if not task: continue

		# Run the task
		task.run()
		
