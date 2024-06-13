package Carrier.CarriOn.Chat;

import Carrier.CarriOn.User.UserEntity;
import Carrier.CarriOn.User.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class ChatService {

    @Autowired
    private ChatRoomRepository chatRoomRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ChatMessageRepository chatMessageRepository;

    private final Map<Long, String> profileImageCache = new HashMap<>();

    private final Map<Long, String> userNameCache = new HashMap<>();
    private final Map<Long, List<ChatMessageDTO>> chatMessageCache = new ConcurrentHashMap<>();
    private final Map<Long, ChatRoomWithLatestMessageDTO> chatRoomCache = new ConcurrentHashMap<>();

    // 채팅방 생성
    public ChatRoom createChatRoom(String name, Set<Long> memberIds) {
        ChatRoom chatRoom = new ChatRoom();
        chatRoom.setName(name);
        Set<UserEntity> members = memberIds.stream()
                .map(id -> userRepository.findById(id).orElseThrow(() -> new RuntimeException("User not found")))
                .collect(Collectors.toSet());
        chatRoom.setParticipants(members);
        return chatRoomRepository.save(chatRoom);
    }

    // 친구 추가시 채팅방 존재하지 않으면 채팅방 생성
    public void createChatRoomIfNotExists(Long userId, Long friendId) {
        Set<Long> memberIds = Set.of(userId, friendId);
        Boolean exists = chatRoomRepository.existsByParticipantsIds(memberIds, memberIds.size());
        if (exists == null || !exists) {
            createChatRoom("Private Chat", memberIds);
        }
    }

    // chatroom id를 통해 채팅방 검색
    public ChatRoom findChatRoomById(Long chatRoomId, Long userId) {
        if (chatRoomId == null || userId == null) {
            throw new IllegalArgumentException("Chat Room ID and User ID must not be null");
        }

        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId)
                .orElseThrow(() -> new RuntimeException("Chat room not found"));

        if (chatRoom.getParticipants().stream().noneMatch(user -> user.getId().equals(userId))) {
            throw new RuntimeException("Unauthorized access to chat room");
        }

        return chatRoom;
    }

    // 채팅방목록에 반환할 해당채팅방 최근메시지 검색 및 최신메시지순으로 정렬
    public List<ChatRoomWithLatestMessageDTO> getChatRoomsWithLatestMessages(Long userId) {
        List<ChatRoom> chatRooms = chatRoomRepository.findByUserId(userId);

        return chatRooms.stream()
                .map(chatRoom -> {
                    if (chatRoomCache.containsKey(chatRoom.getId())) {
                        return chatRoomCache.get(chatRoom.getId());
                    }

                    List<UserEntity> sortedParticipants = chatRoom.getParticipants().stream()
                            .sorted(Comparator.comparing(UserEntity::getId))
                            .collect(Collectors.toList());

                    List<Long> participantIds = sortedParticipants.stream()
                            .map(UserEntity::getId)
                            .collect(Collectors.toList());

                    List<String> participantNames = sortedParticipants.stream()
                            .map(UserEntity::getName)
                            .collect(Collectors.toList());

                    List<String> participantProfileImages = sortedParticipants.stream()
                            .map(this::getProfileImageBase64)
                            .collect(Collectors.toList());

                    ChatMessage latestMessage = chatMessageRepository.findFirstByChatRoomOrderByTimestampDesc(chatRoom);

                    String latestMessageText = latestMessage != null ? latestMessage.getMessage() : null;
                    String latestMessageTimestamp = latestMessage != null ? latestMessage.getTimestamp().toString() : null;
                    Long latestMessageSenderId = latestMessage != null ? latestMessage.getSenderId() : null;
                    String latestMessageSenderName = latestMessageSenderId != null ? userRepository.findById(latestMessageSenderId).orElse(null).getName() : null;

                    ChatRoomWithLatestMessageDTO chatRoomWithLatestMessageDTO = new ChatRoomWithLatestMessageDTO(
                            chatRoom.getId(),
                            chatRoom.getName(),
                            participantIds,
                            participantNames,
                            participantProfileImages,
                            latestMessageText,
                            latestMessageSenderId,
                            latestMessageSenderName,
                            latestMessageTimestamp
                    );

                    chatRoomCache.put(chatRoom.getId(), chatRoomWithLatestMessageDTO);

                    return chatRoomWithLatestMessageDTO;
                })
                .sorted(Comparator.comparing(ChatRoomWithLatestMessageDTO::getLatestMessageTimestamp, Comparator.nullsLast(Comparator.reverseOrder())))
                .collect(Collectors.toList());
    }

    // 해당 채팅방 메시지 반환
    public List<ChatMessageDTO> getChatMessages(Long chatRoomId, Long userId) {
        // 캐시에서 채팅 메시지 확인
        if (chatMessageCache.containsKey(chatRoomId)) {
            return chatMessageCache.get(chatRoomId);
        }

        List<ChatMessage> messages = chatMessageRepository.findByChatRoomId(chatRoomId);
        ChatRoom chatRoom = findChatRoomById(chatRoomId, userId);

        List<String> participantNames = chatRoom.getParticipants().stream()
                .map(UserEntity::getName)
                .collect(Collectors.toList());

        List<ChatMessageDTO> messageDTOs = messages.stream().map(message -> new ChatMessageDTO(
                message.getId(),
                chatRoomId,
                chatRoom.getName(),
                message.getSenderId(),
                getUserNameById(message.getSenderId()),
                message.getMessage(),
                message.getTimestamp().toString(),
                getProfileImageBase64(userRepository.findById(message.getSenderId()).orElseThrow(() -> new RuntimeException("User not found"))),
                participantNames
        )).collect(Collectors.toList());

        // 캐시에 저장
        chatMessageCache.put(chatRoomId, messageDTOs);
        return messageDTOs;
    }

    public void saveMessage(ChatMessage chatMessage) {
        chatMessageRepository.save(chatMessage);

        // 캐시 업데이트
        Long chatRoomId = chatMessage.getChatRoom().getId();
        List<ChatMessageDTO> cachedMessages = chatMessageCache.getOrDefault(chatRoomId, new ArrayList<>());

        if (!cachedMessages.isEmpty()) {
            cachedMessages.add(new ChatMessageDTO(
                    chatMessage.getId(),
                    chatRoomId,
                    chatMessage.getChatRoom().getName(),
                    chatMessage.getSenderId(),
                    getUserNameById(chatMessage.getSenderId()),
                    chatMessage.getMessage(),
                    chatMessage.getTimestamp().toString(),
                    getProfileImageBase64(userRepository.findById(chatMessage.getSenderId()).orElseThrow(() -> new RuntimeException("User not found"))),
                    cachedMessages.isEmpty() ? new ArrayList<>() : cachedMessages.get(0).getParticipantNames()
            ));
        } else {
            // 캐시가 없거나 비어있으면 새로 생성
            List<ChatMessageDTO> messageDTOs = new ArrayList<>();
            messageDTOs.add(new ChatMessageDTO(
                    chatMessage.getId(),
                    chatRoomId,
                    chatMessage.getChatRoom().getName(),
                    chatMessage.getSenderId(),
                    getUserNameById(chatMessage.getSenderId()),
                    chatMessage.getMessage(),
                    chatMessage.getTimestamp().toString(),
                    getProfileImageBase64(userRepository.findById(chatMessage.getSenderId()).orElseThrow(() -> new RuntimeException("User not found"))),
                    chatMessage.getChatRoom().getParticipants().stream().map(UserEntity::getName).collect(Collectors.toList())
            ));
            chatMessageCache.put(chatRoomId, messageDTOs);
        }
        // 채팅방 캐시 업데이트
        updateChatRoomCache(chatRoomId);
    }

    public void invalidateChatRoomCache(Long userId) {
        List<ChatRoom> chatRooms = chatRoomRepository.findByUserId(userId);
        for (ChatRoom chatRoom : chatRooms) {
            chatRoomCache.remove(chatRoom.getId());
            // 채팅방 캐시 갱신 해줘
            updateChatRoomCache(chatRoom.getId());
        }
    }

    private void updateChatRoomCache(Long chatRoomId) {
        ChatRoom chatRoom = chatRoomRepository.findById(chatRoomId).orElseThrow(() -> new RuntimeException("Chat room not found"));
        ChatMessage latestMessage = chatMessageRepository.findFirstByChatRoomOrderByTimestampDesc(chatRoom);

        List<UserEntity> sortedParticipants = chatRoom.getParticipants().stream()
                .sorted(Comparator.comparing(UserEntity::getId))
                .collect(Collectors.toList());

        List<Long> participantIds = sortedParticipants.stream()
                .map(UserEntity::getId)
                .collect(Collectors.toList());

        List<String> participantNames = sortedParticipants.stream()
                .map(UserEntity::getName)
                .collect(Collectors.toList());

        List<String> participantProfileImages = sortedParticipants.stream()
                .map(this::getProfileImageBase64)
                .collect(Collectors.toList());

        String latestMessageText = latestMessage != null ? latestMessage.getMessage() : null;
        String latestMessageTimestamp = latestMessage != null ? latestMessage.getTimestamp().toString() : null;
        Long latestMessageSenderId = latestMessage != null ? latestMessage.getSenderId() : null;
        String latestMessageSenderName = latestMessageSenderId != null ? userRepository.findById(latestMessageSenderId).orElse(null).getName() : null;

        ChatRoomWithLatestMessageDTO chatRoomWithLatestMessageDTO = new ChatRoomWithLatestMessageDTO(
                chatRoom.getId(),
                chatRoom.getName(),
                participantIds,
                participantNames,
                participantProfileImages,
                latestMessageText,
                latestMessageSenderId,
                latestMessageSenderName,
                latestMessageTimestamp
        );

        chatRoomCache.put(chatRoomId, chatRoomWithLatestMessageDTO);
    }


    public String getUserNameById(Long userId) {
        if (userNameCache.containsKey(userId)) {
            return userNameCache.get(userId);
        }
        String userName = userRepository.findById(userId).orElseThrow(() -> new RuntimeException("User not found")).getName();

        userNameCache.put(userId, userName);

        return userName;
    }

    public ChatRoom findGroupChatRoomById(Long groupChatRoomId) {
        return chatRoomRepository.findById(groupChatRoomId).orElseThrow(() -> new RuntimeException("Group chat room not found"));
    }

    // 채팅방 id 반환
    public Long getChatRoomId(Long userId, Long friendId) {
        List<ChatRoom> chatRooms = chatRoomRepository.findByUserId(userId);
        for (ChatRoom chatRoom : chatRooms) {
            Set<Long> participantIds = chatRoom.getParticipants().stream()
                    .map(UserEntity::getId)
                    .collect(Collectors.toSet());
            if (participantIds.contains(friendId)) {
                return chatRoom.getId();
            }
        }
        return null;
    }

    // 사진 가져오기
    public String getProfileImageBase64(UserEntity user) {
        Long userId = user.getId();

        if (profileImageCache.containsKey(userId)) {
            return profileImageCache.get(userId);
        }

        byte[] profileImageBytes = user.getProfileImage();
        if (profileImageBytes == null) {
            profileImageBytes = new byte[0];
        }
        String profileImageBase64 = Base64.getEncoder().encodeToString(profileImageBytes);
        profileImageCache.put(userId, profileImageBase64);
        return profileImageBase64;
    }
}
