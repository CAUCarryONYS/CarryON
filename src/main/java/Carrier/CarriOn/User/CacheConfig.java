package Carrier.CarriOn.User;

import Carrier.CarriOn.Chat.ChatRoomWithLatestMessageDTO;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Configuration
public class CacheConfig {

    @Bean
    public Map<Long, ChatRoomWithLatestMessageDTO> chatRoomCache() {
        return new ConcurrentHashMap<>();
    }
}
