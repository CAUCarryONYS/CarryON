package Carrier.CarriOn.Chat;

import Carrier.CarriOn.User.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.*;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    private final ObjectMapper objectMapper;
    private final ChatService chatService;

    private final UserRepository userRepository;

    public WebSocketConfig(ObjectMapper objectMapper, ChatService chatService, UserRepository userRepository) {
        this.objectMapper = objectMapper;
        this.chatService = chatService;
        this.userRepository = userRepository;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(chatHandler(), "/ws/{userId}")
                .setAllowedOrigins("*");
    }

    @Bean
    public ChatHandler chatHandler() {
        return new ChatHandler(objectMapper, chatService, userRepository);
    }
}
