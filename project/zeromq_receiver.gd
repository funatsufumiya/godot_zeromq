class_name ZeroMQReceiver
extends Node

enum TestMode {
	PUSH_PULL = 1,
	PUB_SUB = 2,
	REQ_REP = 3
}

# @export var zmq_test_mode:TestMode = TestMode.REQ_REP
@export var zmq_test_mode:TestMode = TestMode.PUSH_PULL

@onready var zmq_sender:ZMQSender = create_zmq_sender()
@onready var zmq_receiver:ZMQReceiver = create_zmq_receiver()

@onready var counter:int = 0

func create_zmq_sender():
	var zmq_out_address = get_zmq_out_address()
	var zmq_out_socket_type = get_zmq_out_socket_type()
	var zmq_out_connection_mode = get_zmq_out_connection_mode()
	var zmq_receive_on_sender = get_zmq_receive_on_sender()

	return ZMQSender.new_from(zmq_out_address, zmq_out_socket_type, zmq_out_connection_mode, "", zmq_receive_on_sender)

func create_zmq_receiver():
	var zmq_in_address = get_zmq_in_address()
	var zmq_in_socket_type = get_zmq_in_socket_type()
	var zmq_in_connection_mode = get_zmq_in_connection_mode()
	var zmq_receive_on_sender = get_zmq_receive_on_sender()

	return ZMQReceiver.new_from(zmq_in_address, zmq_in_socket_type, zmq_in_connection_mode, "")

func get_zmq_in_address():
	return "tcp://localhost:5555"

func get_zmq_out_address():
	return "tcp://localhost:5555"

func get_zmq_in_socket_type():
	match zmq_test_mode:
		TestMode.PUSH_PULL:
			return ZMQ.SocketType.PULL
		TestMode.PUB_SUB:
			return ZMQ.SocketType.SUB
		TestMode.REQ_REP:
			return ZMQ.SocketType.REP

func get_zmq_out_socket_type():
	match zmq_test_mode:
		TestMode.PUSH_PULL:
			return ZMQ.SocketType.PUSH
		TestMode.PUB_SUB:
			return ZMQ.SocketType.PUB
		TestMode.REQ_REP:
			return ZMQ.SocketType.REQ

func get_zmq_in_connection_mode():
	match zmq_test_mode:
		TestMode.PUSH_PULL:
			return ZMQ.ConnectionMode.BIND
		TestMode.PUB_SUB:
			return ZMQ.ConnectionMode.CONNECT
		TestMode.REQ_REP:
			return ZMQ.ConnectionMode.BIND

func get_zmq_out_connection_mode():
	match zmq_test_mode:
		TestMode.PUSH_PULL:
			return ZMQ.ConnectionMode.CONNECT
		TestMode.PUB_SUB:
			return ZMQ.ConnectionMode.BIND
		TestMode.REQ_REP:
			return ZMQ.ConnectionMode.CONNECT

func get_zmq_receive_on_sender():
	match zmq_test_mode:
		TestMode.PUSH_PULL:
			return false
		TestMode.PUB_SUB:
			return false
		TestMode.REQ_REP:
			return true

# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(zmq_receiver)
	# add_child(zmq_sender)

	# Message input Handler 
	zmq_receiver.onMessageString(func(str: String):
		print("[ZMQ Receiver] Received: ", str)

		if zmq_test_mode == TestMode.REQ_REP:
			zmq_receiver.sendString("Response: " + str(counter))
	)

	if zmq_test_mode == TestMode.REQ_REP:
		zmq_sender.onMessageString(func(str: String):
			# print("[ZMQ Sender] Received: ", str)

			await get_tree().create_timer(1.0).timeout
			counter += 1
			print("[ZMQ Sender] Sending: ", "Request " + str(counter))
			zmq_sender.sendString("Request " + str(counter))
		)

	# Message output Handler
	if zmq_test_mode == TestMode.REQ_REP:
		counter = 1
		print("[ZMQ Sender] Sending: ", "Request " + str(counter))
		zmq_sender.sendString("Request " + str(counter))
	else:
		while true:
			counter += 1
			await get_tree().create_timer(1.0).timeout
			zmq_sender.sendString("Hello World " + str(counter))

func _exit_tree():
	zmq_receiver.stop()
	zmq_sender.stop()
	remove_child(zmq_receiver)
	remove_child(zmq_sender)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
