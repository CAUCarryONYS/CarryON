package Carrier.CarriOn.Chat;

public class ChatMessageRequest {
    private Long senderId;
    private Long chatRoomId;
    private String message;

    // 기본 생성자
    public ChatMessageRequest() {
    }

    // 매개변수가 있는 생성자
    public ChatMessageRequest(Long senderId, Long chatRoomId, String message) {
        this.senderId = senderId;
        this.chatRoomId = chatRoomId;
        this.message = message;
    }

    // Getter와 Setter
    public Long getSenderId() {
        return senderId;
    }

    public void setSenderId(Long senderId) {
        this.senderId = senderId;
    }

    public Long getChatRoomId() {
        return chatRoomId;
    }

    public void setChatRoomId(Long chatRoomId) {
        this.chatRoomId = chatRoomId;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
