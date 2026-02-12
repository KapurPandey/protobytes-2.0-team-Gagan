<?php

error_reporting(E_ALL);
ini_set('display_errors', 1);
header('Content-Type: application/json');

// Step 1: Connect to the database
// Step 1: Connect to the database
include 'db_config.php';


// // shutdown
// echo json_encode(["status" => "Unauthorized access", "msg" => "Only authorized users can access this app.
// Contact the admin if you believe you should have access."]);
// $conn->close();
// exit;

// Step 1: Get POST data (now including secondparty)
$input = json_decode(file_get_contents("php://input"), true);
if (!isset($input['username'], $input['amount'], $input['timestamp'], $input['signature'], $input['secondparty'])) {
    echo json_encode(["status" => "error", "msg" => "Missing fields"]);
    exit;
}

$username = $input['username'];
$secondparty = $input['secondparty'];
$amount = $input['amount'];
$timestamp = $input['timestamp'];
$signature_b64 = $input['signature'];

// Step 2: Connect to DB
// Step 2: Connect to DB (Already connected in db_config.php)
// $conn = new mysqli($servername, $username, $password, $database);

if ($conn->connect_error) {
    echo json_encode(["status" => "error", "msg" => "DB connection failed: " . $conn->connect_error]);
    exit;
}

// Step 3a: Fetch balance and public key from user_info (username - sender)
$stmt = $conn->prepare("SELECT balance, public_key FROM user_info WHERE username = ?");
if (!$stmt) {
    echo json_encode(["status" => "error", "msg" => "Prepare failed: " . $conn->error]);
    $conn->close();
    exit;
}
$stmt->bind_param("s", $username);
$stmt->execute();
$stmt->bind_result($balance, $public_key_b64);
if (!$stmt->fetch()) {
    echo json_encode(["status" => "error", "msg" => "User not found"]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

// Step 3b: Fetch balance of secondparty (receiver)
$stmt = $conn->prepare("SELECT balance FROM user_info WHERE username = ?");
if (!$stmt) {
    echo json_encode(["status" => "error", "msg" => "Prepare failed: " . $conn->error]);
    $conn->close();
    exit;
}
$stmt->bind_param("s", $secondparty);
$stmt->execute();
$stmt->bind_result($receiver_balance);
if (!$stmt->fetch()) {
    echo json_encode(["status" => "error", "msg" => "Second party user not found"]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

// Step 4: Check balance
if ($balance < $amount) {
    echo json_encode(["status" => "error", "msg" => "Insufficient balance"]);
    $conn->close();
    exit;
}

// Step 5: Check if signature already used (qr_hash)
$stmt2 = $conn->prepare("SELECT id FROM transactions WHERE qr_hash = ?");
if (!$stmt2) {
    echo json_encode(["status" => "error", "msg" => "Prepare failed: " . $conn->error]);
    $conn->close();
    exit;
}
$stmt2->bind_param("s", $signature_b64);
$stmt2->execute();
$stmt2->store_result();
if ($stmt2->num_rows > 0) {
    echo json_encode(["status" => "error", "msg" => "QR already used"]);
    $stmt2->close();
    $conn->close();
    exit;
}
$stmt2->close();

// Step 6: Verify signature using Ed25519
$public_key = base64_decode(trim($public_key_b64));
$signature = base64_decode($signature_b64);
$message = $username . $amount . $timestamp;

$is_valid = sodium_crypto_sign_verify_detached($signature, $message, $public_key);

if (!$is_valid) {
    echo json_encode(["status" => "error", "msg" => "Invalid signature"]);
    $conn->close();
    exit;
}

// ----- Transactional update to ensure both accounts updated atomically -----
$conn->autocommit(FALSE); // Start transaction

$error = false;

// Step 7a: Deduct amount from sender (username)
$stmt = $conn->prepare("UPDATE user_info SET balance = balance - ? WHERE username = ?");
if (!$stmt) {
    $error = "Prepare failed (deduct): " . $conn->error;
} else {
    $stmt->bind_param("ds", $amount, $username);
    if (!$stmt->execute()) {
        $error = "Execute failed (deduct): " . $stmt->error;
    }
    $stmt->close();
}

// Step 7b: Credit amount to receiver (secondparty)
if (!$error) {
    $stmt = $conn->prepare("UPDATE user_info SET balance = balance + ? WHERE username = ?");
    if (!$stmt) {
        $error = "Prepare failed (credit): " . $conn->error;
    } else {
        $stmt->bind_param("ds", $amount, $secondparty);
        if (!$stmt->execute()) {
            $error = "Execute failed (credit): " . $stmt->error;
        }
        $stmt->close();
    }
}
$txn_id = bin2hex(random_bytes(16)); // unique transaction grouping
$timestamp = time(); // always use server timestamp

// Step 7c: Double-entry ledger (debit for sender, credit for receiver)
if (!$error) {

    // Use server timestamp for consistency
    $timestamp = time();
    $txn_id = bin2hex(random_bytes(16)); // group both entries

    // 7c-1: Sender debit
    $stmt3 = $conn->prepare("
        INSERT INTO transactions 
        (username, type, amount, timestamp, qr_hash, payment_status, remarks, secondparty)
        VALUES (?, 'debit', ?, ?, ?, 'completed', ?, ?)
    ");

    if (!$stmt3) {
        $error = "Prepare failed (debit log): " . $conn->error;
    } else {
        $remark_sender = "Sent to $secondparty | TXN:$txn_id";
        $stmt3->bind_param("sdisss", 
            $username, 
            $amount, 
            $timestamp, 
            $signature_b64, 
            $remark_sender,
            $secondparty
        );

        if (!$stmt3->execute()) {
            $error = "Execute failed (debit log): " . $stmt3->error;
        }
        $stmt3->close();
    }

    // 7c-2: Receiver credit
    if (!$error) {
        $stmt4 = $conn->prepare("
            INSERT INTO transactions 
            (username, type, amount, timestamp, qr_hash, payment_status, remarks, secondparty)
            VALUES (?, 'credit', ?, ?, ?, 'completed', ?, ?)
        ");

        if (!$stmt4) {
            $error = "Prepare failed (credit log): " . $conn->error;
        } else {
            $remark_receiver = "Received from $username | TXN:$txn_id";
            $stmt4->bind_param("sdisss", 
                $secondparty, 
                $amount, 
                $timestamp, 
                $signature_b64, 
                $remark_receiver,
                $username
            );

            if (!$stmt4->execute()) {
                $error = "Execute failed (credit log): " . $stmt4->error;
            }
            $stmt4->close();
        }
    }
}

if ($error) {
    $conn->rollback();
    echo json_encode(["status" => "error", "msg" => $error]);
    $conn->close();
    exit;
} else {
    $conn->commit();
}

// Success response
echo json_encode(["status" => "success", "msg" => "Transaction Succesful!"]);
$conn->close();
exit;
