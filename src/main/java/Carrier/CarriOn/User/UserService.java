package Carrier.CarriOn.User;

import Carrier.CarriOn.Chat.ChatRoom;
import Carrier.CarriOn.Chat.ChatRoomRepository;
import Carrier.CarriOn.Chat.ChatRoomWithLatestMessageDTO;
import Carrier.CarriOn.Chat.ChatService;
import Carrier.CarriOn.Friend.FriendDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final ChatService chatService;

    private final ChatRoomRepository chatRoomRepository;
    private final Map<Long, String> profileImageCache = new ConcurrentHashMap<>();
    private final Map<Long, List<FriendDTO>> friendListCache = new ConcurrentHashMap<>();
    private final Map<Long, Long> friendListCacheTime = new ConcurrentHashMap<>();

    private final Map<Long, ChatRoomWithLatestMessageDTO> chatRoomCache;

    private static final long CACHE_VALIDITY_DURATION = TimeUnit.MINUTES.toMillis(10); // 캐시 유효 시간 설정

    @Autowired
    public UserService(UserRepository userRepository, ChatService chatService, ChatRoomRepository chatRoomRepository, Map<Long, ChatRoomWithLatestMessageDTO> chatRoomCache) {
        this.userRepository = userRepository;
        this.chatService = chatService;
        this.chatRoomRepository = chatRoomRepository;
        this.chatRoomCache = chatRoomCache;
    }

    public void addFriend(Long userId, String friendLoginId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        UserEntity friend = userRepository.findByLoginId(friendLoginId)
                .orElseThrow(() -> new UserNotFoundException("Friend not found"));

        if (user.getFriends().contains(friend)) {
            throw new IllegalArgumentException("이미 친구로 추가된 사용자입니다.");
        }

        user.getFriends().add(friend);
        friend.getFriends().add(user);
        userRepository.save(user);
        userRepository.save(friend);

        // 친구 추가 후 채팅방 생성
        chatService.createChatRoomIfNotExists(userId, friend.getId());

        // 친구 추가 시 캐시 무효화
        invalidateFriendListCache(userId);
        invalidateFriendListCache(friend.getId());
    }

    public void removeFriend(Long userId, Long friendId) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found"));
        UserEntity friend = userRepository.findById(friendId)
                .orElseThrow(() -> new UserNotFoundException("Friend not found"));

        boolean isUserFriendRemoved = user.getFriends().remove(friend);
        boolean isFriendUserRemoved = friend.getFriends().remove(user);

        if (!isUserFriendRemoved || !isFriendUserRemoved) {
            throw new IllegalArgumentException("해당 친구가 존재하지 않습니다.");
        }

        userRepository.save(user);
        userRepository.save(friend);

        // 친구 삭제 시 캐시 무효화
        invalidateFriendListCache(userId);
        invalidateFriendListCache(friendId);
    }

    public List<FriendDTO> getFriendListWithIds(Long userId) {
        // 캐시에서 친구 목록 확인
        if (friendListCache.containsKey(userId) && !isCacheExpired(userId)) {
            return friendListCache.get(userId);
        }

        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        List<FriendDTO> friends = new ArrayList<>();
        Set<UserEntity> userFriends = user.getFriends();

        for (UserEntity friend : userFriends) {
            Long chatRoomId = chatService.getChatRoomId(user.getId(), friend.getId());
            String profileImageBase64 = getProfileImageBase64(friend);
            friends.add(new FriendDTO(friend.getId(), friend.getName(), chatRoomId, profileImageBase64));
        }

        // 이름 오름차순으로 정렬
        friends.sort(Comparator.comparing(FriendDTO::getName));

        // 캐시에 저장
        friendListCache.put(userId, friends);
        friendListCacheTime.put(userId, System.currentTimeMillis());

        return friends;
    }

    public void updateUser(Long userId, UserUpdateRequest updateRequest) {
        UserEntity user = userRepository.findById(userId)
                .orElseThrow(() -> new UserNotFoundException("User not found"));

        boolean isUpdated = false;

        if (updateRequest.getName() != null && !updateRequest.getName().equals(user.getName())) {
            user.setName(updateRequest.getName());
            isUpdated = true;
        }

        if (updateRequest.getPassword() != null && !updateRequest.getPassword().equals(user.getPassword())) {
            user.setPassword(updateRequest.getPassword());
            isUpdated = true;
        }

        if (updateRequest.getProfileImage() != null) {
            byte[] profileImageBytes = Base64.getDecoder().decode(updateRequest.getProfileImage());
            user.setProfileImage(profileImageBytes);
            profileImageCache.put(userId, updateRequest.getProfileImage());
            isUpdated = true;
        }

        if (isUpdated) {
            userRepository.save(user);
            // 유저가 참여한 채팅방의 캐시 무효화 또는 갱신
            invalidateChatRoomCache(userId);
        }
    }

    private void invalidateChatRoomCache(Long userId) {
        List<ChatRoom> chatRooms = chatRoomRepository.findByUserId(userId);
        for (ChatRoom chatRoom : chatRooms) {
            chatRoomCache.remove(chatRoom.getId());
        }
    }


    private boolean isCacheExpired(Long userId) {
        Long cacheTime = friendListCacheTime.get(userId);
        return cacheTime == null || (System.currentTimeMillis() - cacheTime) > CACHE_VALIDITY_DURATION;
    }

    private void invalidateFriendListCache(Long userId) {
        friendListCache.remove(userId);
        friendListCacheTime.remove(userId);
    }

    public String getProfileImageBase64(UserEntity user) {
        Long userId = user.getId();

        // 캐시에서 프로필 이미지 Base64 확인
        if (profileImageCache.containsKey(userId)) {
            return profileImageCache.get(userId);
        }

        // 프로필 이미지가 없는 경우 기본 이미지 사용
        byte[] profileImageBytes = user.getProfileImage();
        if (profileImageBytes == null) {
            // 기본 이미지 설정 (여기서는 비어있는 문자열로 설정)
            profileImageBytes = new byte[0];
        }

        // Base64로 인코딩
        String profileImageBase64 = Base64.getEncoder().encodeToString(profileImageBytes);

        // 캐시에 저장
        profileImageCache.put(userId, profileImageBase64);

        return profileImageBase64;
    }
}
