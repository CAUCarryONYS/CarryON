package Carrier.CarriOn.Chat;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ChatMessageRequest {
    private Long senderId;
    private Long chatRoomId;
    private String message;

    public ChatMessageRequest() {
    }

    public ChatMessageRequest(Long senderId, Long chatRoomId, String message) {
        this.senderId = senderId;
        this.chatRoomId = chatRoomId;
        this.message = message;
    }

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
