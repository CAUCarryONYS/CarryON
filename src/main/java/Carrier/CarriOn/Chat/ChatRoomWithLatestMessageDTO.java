package Carrier.CarriOn.Chat;

import java.util.List;

public class ChatRoomWithLatestMessageDTO {
    private Long chatRoomId;
    private String chatRoomName; // chatRoomName 추가
    private List<Long> participantIds;
    private List<String> participantNames;
    private List<String> participantProfileImages;
    private String latestMessage;
    private Long latestMessageSenderId;
    private String latestMessageSenderName;
    private String latestMessageTimestamp;

    // Constructor
    public ChatRoomWithLatestMessageDTO(Long chatRoomId, String chatRoomName, List<Long> participantIds, List<String> participantNames, List<String> participantProfileImages, String latestMessage, Long latestMessageSenderId, String latestMessageSenderName, String latestMessageTimestamp) {
        this.chatRoomId = chatRoomId;
        this.chatRoomName = chatRoomName; // chatRoomName 추가
        this.participantIds = participantIds;
        this.participantNames = participantNames;
        this.participantProfileImages = participantProfileImages;
        this.latestMessage = latestMessage;
        this.latestMessageSenderId = latestMessageSenderId;
        this.latestMessageSenderName = latestMessageSenderName;
        this.latestMessageTimestamp = latestMessageTimestamp;
    }

    // Getters and setters
    public Long getChatRoomId() {
        return chatRoomId;
    }

    public void setChatRoomId(Long chatRoomId) {
        this.chatRoomId = chatRoomId;
    }

    public String getChatRoomName() {
        return chatRoomName;
    }

    public void setChatRoomName(String chatRoomName) {
        this.chatRoomName = chatRoomName;
    }

    public List<Long> getParticipantIds() {
        return participantIds;
    }

    public void setParticipantIds(List<Long> participantIds) {
        this.participantIds = participantIds;
    }

    public List<String> getParticipantNames() {
        return participantNames;
    }

    public void setParticipantNames(List<String> participantNames) {
        this.participantNames = participantNames;
    }

    public List<String> getParticipantProfileImages() {
        return participantProfileImages;
    }

    public void setParticipantProfileImages(List<String> participantProfileImages) {
        this.participantProfileImages = participantProfileImages;
    }

    public String getLatestMessage() {
        return latestMessage;
    }

    public void setLatestMessage(String latestMessage) {
        this.latestMessage = latestMessage;
    }

    public Long getLatestMessageSenderId() {
        return latestMessageSenderId;
    }

    public void setLatestMessageSenderId(Long latestMessageSenderId) {
        this.latestMessageSenderId = latestMessageSenderId;
    }

    public String getLatestMessageSenderName() {
        return latestMessageSenderName;
    }

    public void setLatestMessageSenderName(String latestMessageSenderName) {
        this.latestMessageSenderName = latestMessageSenderName;
    }

    public String getLatestMessageTimestamp() {
        return latestMessageTimestamp;
    }

    public void setLatestMessageTimestamp(String latestMessageTimestamp) {
        this.latestMessageTimestamp = latestMessageTimestamp;
    }
}
