#include <mlixir/mlixir.h>

namespace mlixir {

std::string get_project_version() {
  return mlixir::MLIXIR_VERSION;
}

}  // namespace mlixir